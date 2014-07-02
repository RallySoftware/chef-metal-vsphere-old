require 'chef_metal/driver'
require 'chef_metal/machine/windows_machine'
require 'chef_metal/machine/unix_machine'
require 'chef_metal/machine_spec'
require 'chef_metal/convergence_strategy/install_msi'
require 'chef_metal/convergence_strategy/install_sh'
require 'chef_metal/convergence_strategy/install_cached'
require 'chef_metal/convergence_strategy/no_converge'
require 'chef_metal/transport/ssh'
require 'chef_metal/transport/winrm'
require 'chef_metal_vsphere/version'
require 'vmonkey'

module ChefMetalVsphere
  # Provisions machines in VMware vSphere.
  class VsphereDriver < ChefMetal::Driver
    DEFAULT_OPTIONS = {
      :create_timeout => 300,
      :start_timeout => 180,
      :ssh_timeout => 20
    }

    def self.from_url(url, config)
      VsphereDriver.new(url, config)
    end

    def self.canonicalize_url(driver_url, config)
      _, host, datacenter, cluster = driver_url.split(':', 4)
      vmonkey_opts = VMonkey.default_opts

      host       ||= vmonkey_opts[:host]
      datacenter ||= vmonkey_opts[:datacenter]
      cluster    ||= vmonkey_opts[:cluster]

      [ "vsphere:#{host}:#{datacenter}:#{cluster}", config ]
    end

    def initialize(url, config)
      super(url, config)
    end

    def allocate_machine(action_handler, machine_spec, machine_options)
      create_vm(action_handler, machine_spec, machine_options)
    end

    def ready_machine(action_handler, machine_spec, machine_options)
      vm = vm_for(machine_spec)

      if vm.nil?
        raise "Machine #{machine_spec.name} does not have a vm associated with it, or vm does not exist."
      end

      # Start the vm if needed, and wait for it to start
      start_vm(action_handler, machine_spec, vm)
      wait_until_ready(action_handler, machine_spec, machine_options, vm)
      wait_for_transport(action_handler, machine_spec, machine_options, vm)

      machine_for(machine_spec, machine_options, vm)
    end


    def destroy_machine(action_handler, machine_spec, machine_options)
      vm = vm_for(machine_spec)
      if vm
        action_handler.perform_action "destroy machine #{machine_spec.name} (#{machine_spec.location['instance_uuid']} at #{driver_url})" do
          vm.destroy
          machine_spec.location = nil
        end
      end
      strategy = convergence_strategy_for(machine_spec, machine_options)
      strategy.cleanup_convergence(action_handler, machine_spec)
    end

    def transport_for(machine_spec, machine_options, vm)
      # TODO winrm
      create_ssh_transport(machine_spec, machine_options, vm)
    end

    protected
    def option_for(machine_options, key)
      machine_options[key] || DEFAULT_OPTIONS[key]
    end

    def monkey
      ## TODO - test @vim and reconnect on error - idle sessions get silently timed-out by vSphere  :P
      @vim ||= VMonkey.connect
    end

    def create_vm(action_handler, machine_spec, machine_options)
      if machine_spec.location
        if machine_spec.location['driver_url'] != driver_url
          raise "Switching a machine's driver from #{machine_spec.location['driver_url']} to #{driver_url} for is not currently supported!  Use machine :destroy and then re-create the machine on the new driver."
        end

        vm = vm_for!(machine_spec)
        if vm
          return vm
        else
          Chef::Log.warn "Machine #{machine_spec.name} (#{machine_spec.location['instance_uuid']} on #{driver_url}) no longer exists.  Recreating ..."
        end
      end

      bootstrap_options = bootstrap_options_for(action_handler, machine_spec, machine_options)

      description = [ "creating machine #{machine_spec.name} on #{driver_url}" ]
      bootstrap_options.each_pair { |key,value| description << "  #{key}: #{value.inspect}" }
      action_handler.report_progress description
      vm = nil
      if action_handler.should_perform_actions
        template = monkey.vm! bootstrap_options[:template]
        vm_path = "#{bootstrap_options[:folder]}/#{machine_spec.name}"
        vm = template.clone_to vm_path

        machine_spec.location = {
          'driver_url' => driver_url,
          'driver_version' => ChefMetalVsphere::VERSION,
          'cloned_from' => bootstrap_options[:template],
          'path' => vm_path,
          'instance_uuid' => vm.config.instanceUuid,
          'allocated_at' => Time.now.to_i
        }
        machine_spec.location['key_name'] = bootstrap_options[:key_name] if bootstrap_options[:key_name]
        %w(is_windows ssh_username sudo ssh_gateway).each do |key|
          machine_spec.location[key] = machine_options[key.to_sym] if machine_options[key.to_sym]
        end

        action_handler.performed_action "machine #{machine_spec.name} created as #{vm.config.instanceUuid} on #{driver_url}"
      end
      vm
    end

    def start_vm(action_handler, machine_spec, vm)
      unless vm.started?
        action_handler.perform_action "start machine #{machine_spec.name} (#{vm.config.instanceUuid} on #{driver_url})" do
          vm.start
          machine_spec.location['started_at'] = Time.now.to_i
        end
        machine_spec.save(action_handler)
      end
    end

    def remaining_wait_time(machine_spec, machine_options)
      if machine_spec.location['started_at']
        timeout = option_for(machine_options, :start_timeout) - (Time.now.utc - parse_time(machine_spec.location['started_at']))
      else
        timeout = option_for(machine_options, :create_timeout) - (Time.now.utc - parse_time(machine_spec.location['allocated_at']))
      end
      timeout > 0 ? timeout : 0.01
    end

    def parse_time(value)
      if value.is_a?(String)
        Time.parse(value)
      else
        Time.at(value)
      end
    end

    def wait_until_ready(action_handler, machine_spec, machine_options, vm)
      unless vm.ready?
        if action_handler.should_perform_actions
          action_handler.report_progress "waiting for #{machine_spec.name} (#{vm.config.instanceUuid} on #{driver_url}) to be ready ..."
          vm.wait_for(remaining_wait_time(machine_spec, machine_options)) { vm.ready? }
          action_handler.report_progress "#{machine_spec.name} is now ready"
        end
      end
    end

    def wait_for_transport(action_handler, machine_spec, machine_options, vm)
      transport = transport_for(machine_spec, machine_options, vm)
      if !transport.available?
        if action_handler.should_perform_actions
          action_handler.report_progress "waiting for #{machine_spec.name} (#{vm.config.instanceUuid} on #{driver_url}) to be connectable (transport up and running) ..."

          _self = self

          vm.wait_for(remaining_wait_time(machine_spec, machine_options)) do
            transport.available?
          end
          action_handler.report_progress "#{machine_spec.name} is now connectable"
        end
      end
    end

    def symbolize_keys(options)
      options.inject({}) do |result,(key,value)|
        result[key.to_sym] = value
        result
      end
    end

    def vm_for(machine_spec)
      if machine_spec.location
        monkey.vm_by_instance_uuid machine_spec.location['instance_uuid']
      else
        nil
      end
    end

    def vm_for!(machine_spec)
      monkey.vm_by_instance_uuid! machine_spec.location['instance_uuid']
    end

    def bootstrap_options_for(action_handler, machine_spec, machine_options)
      bootstrap_options = symbolize_keys(machine_options[:bootstrap_options] || {})

      bootstrap_options[:tags]  = default_tags(machine_spec, bootstrap_options[:tags] || {})

      bootstrap_options[:name] ||= machine_spec.name

      bootstrap_options
    end

    def default_tags(machine_spec, bootstrap_tags = {})
      tags = {
          'Name' => machine_spec.name,
          'BootstrapId' => machine_spec.id,
          'BootstrapHost' => Socket.gethostname,
          'BootstrapUser' => Etc.getlogin
      }
      # User-defined tags override the ones we set
      tags.merge(bootstrap_tags)
    end

    def machine_for(machine_spec, machine_options, vm = nil)
      vm ||= vm_for(machine_spec)
      if !vm
        raise "VM for node #{machine_spec.name} has not been created!"
      end

      if machine_spec.location['is_windows']
        ChefMetal::Machine::WindowsMachine.new(machine_spec, transport_for(machine_spec, machine_options, vm), convergence_strategy_for(machine_spec, machine_options))
      else
        ChefMetal::Machine::UnixMachine.new(machine_spec, transport_for(machine_spec, machine_options, vm), convergence_strategy_for(machine_spec, machine_options))
      end
    end

    def convergence_strategy_for(machine_spec, machine_options)
      # Defaults
      if !machine_spec.location
        return ChefMetal::ConvergenceStrategy::NoConverge.new(machine_options[:convergence_options], config)
      end

      if machine_spec.location['is_windows']
        ChefMetal::ConvergenceStrategy::InstallMsi.new(machine_options[:convergence_options], config)
      elsif machine_options[:cached_installer] == true
        ChefMetal::ConvergenceStrategy::InstallCached.new(machine_options[:convergence_options], config)
      else
        ChefMetal::ConvergenceStrategy::InstallSh.new(machine_options[:convergence_options], config)
      end
    end

    def ssh_options_for(machine_spec, machine_options, vm)
      result = {
        :auth_methods => [ 'publickey' ],
        :keys_only => true,
        :host_key_alias => vm.config.instanceUuid
      }.merge(machine_options[:ssh_options] || {})
      if vm.respond_to?(:private_key) && vm.private_key
        result[:key_data] = [ vm.private_key ]
      elsif vm.respond_to?(:key_name) && vm.key_name
        key = get_private_key(vm.key_name)
        if !key
          raise "VM has key name '#{vm.key_name}', but the corresponding private key was not found locally.  Check if the key is in Chef::Config.private_key_paths: #{Chef::Config.private_key_paths.join(', ')}"
        end
        result[:key_data] = [ key ]
      elsif machine_spec.location['key_name']
        key = get_private_key(machine_spec.location['key_name'])
        if !key
          raise "VM was created with key name '#{machine_spec.location['key_name']}', but the corresponding private key was not found locally.  Check if the key is in Chef::Config.private_key_paths: #{Chef::Config.private_key_paths.join(', ')}"
        end
        result[:key_data] = [ key ]
      elsif machine_options[:bootstrap_options][:key_path]
        result[:key_data] = [ IO.read(machine_options[:bootstrap_options][:key_path]) ]
      elsif machine_options[:bootstrap_options][:key_name]
        result[:key_data] = [ get_private_key(machine_options[:bootstrap_options][:key_name]) ]
      elsif machine_options[:ssh_options] && machine_options[:ssh_options][:password]
        result[:password]     = machine_options[:ssh_options][:password]
        result[:auth_methods] = [ 'password' ]
        result[:keys]         = [ ]
        result[:keys_only]    = false
      else
        # TODO make a way to suggest other keys to try ...
        raise "No key found to connect to #{machine_spec.name} (#{machine_spec.location.inspect})!"
      end
      result
    end

    def default_ssh_username(machine_options)
      if machine_options[:ssh_options] && machine_options[:ssh_options][:user]
        machine_options[:ssh_options][:user]
      else
        'root'
      end
    end

    def create_ssh_transport(machine_spec, machine_options, vm)
      ssh_options = ssh_options_for(machine_spec, machine_options, vm)
      username = machine_spec.location['ssh_username'] || default_ssh_username(machine_options)
      if machine_options.has_key?(:ssh_username) && machine_options[:ssh_username] != machine_spec.location['ssh_username']
        Chef::Log.warn("VM #{machine_spec.name} was created with SSH username #{machine_spec.location['ssh_username']} and machine_options specifies username #{machine_options[:ssh_username]}.  Using #{machine_spec.location['ssh_username']}.  Please edit the node and change the metal.location.ssh_username attribute if you want to change it.")
      end
      options = {}
      if machine_spec.location[:sudo] || (!machine_spec.location.has_key?(:sudo) && username != 'root')
        options[:prefix] = 'sudo '
      end

      if vm.guest_ip.nil?
        raise "VM #{machine_spec.name} (#{vm.config.instanceUuid} has no IP address!"
      end

      #Enable pty by default
      options[:ssh_pty_enable] = true
      options[:ssh_gateway] = machine_spec.location['ssh_gateway'] if machine_spec.location.has_key?('ssh_gateway')

      ChefMetal::Transport::SSH.new(vm.guest_ip, username, ssh_options, options, config)
    end

  end
end


