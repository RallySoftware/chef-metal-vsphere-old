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
    def self.from_url(url, config)
      VsphereDriver.new(url, config)
    end

    def self.canonicalize_url(driver_url, config)
      _, host, datacenter, cluster = driver_url.split(':', 4)
      host       ||= config[:host]
      datacenter ||= config[:datacenter]
      cluster    ||= config[:cluster]

      [ "vsphere:#{host}:#{datacenter}:#{cluster}", config ]
    end

    def inspekt(o, label='FINDME')
      Chef::Log.warn "INSPEKT #{label}: #{o.inspect}"
    end

    def punt(s='punt!')
      raise s
    end

    def initialize(url, config)
      super(url, config)
    end

    def allocate_machine(action_handler, machine_spec, machine_options)
      create_vm(action_handler, machine_spec, machine_options)
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


    protected
    def monkey
      ## TODO - test @vim and reconnect on error - idle sessions get timed-out by vSphere  :P
      @vim ||= VMonkey.connect()
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
        inspekt bootstrap_options, 'bootstrap_options'

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
      end
      action_handler.performed_action "machine #{machine_spec.name} created as #{vm.config.instanceUuid} on #{driver_url}"
      vm
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

  end
end


