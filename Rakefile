require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'mixlib/shellout'
require 'vmonkey'

def shell_out(*command_args)
  cmd = Mixlib::ShellOut.new(command_args)
  cmd.live_stream = STDOUT
  cmd.run_command
  cmd
end

def shell_out!(*command_args)
  cmd = shell_out(*command_args)
  cmd.error!
  cmd
end

task :vmonkey do |t|
  ENV['VMONKEY_YML'] ||= File.expand_path(File.join(File.dirname(__FILE__), 'test', '.vmonkey'))

  instructions = "
    For the integration tests to run with the vsphere driver, you need:
      - On the machine running the specs:
        + #{ENV['VMONKEY_YML']} (see below)

      - On your vSphere system
        + A VM or Template from which VMs will be cloned (:bootstrap_options => :template)
        + A working Folder into which VMs will be cloned (:bootstrap_options => :working_folder)
        + Clones of the Template must provide SSH port 22 with root password authentication (:ssh_options => :password)

    Place the following in #{ENV['VMONKEY_YML']}
      host: vcenter_host_name
      user: vcenter_user_name
      password: your_mothers_maiden_name
      insecure: true
      ssl: true
      datacenter: datacenter_name
      cluster: cluster_name
      test:
        :bootstrap_options:
          template: /path/to/a/vm/template
          folder: /path/to/a/folder/to/place/new/vms
        :ssh_options:
          password: your_first_pet
    "

  begin
    File.read ENV['VMONKEY_YML']
  rescue => e
    puts instructions
    raise e
  end

  monkey = VMonkey.connect

  TEST_CONFIG = monkey.opts[:test]
  raise instructions unless TEST_CONFIG
  raise instructions unless TEST_CONFIG[:ssh_options]
  raise instructions unless TEST_CONFIG[:ssh_options][:password]
  raise instructions unless TEST_CONFIG[:bootstrap_options]
  raise instructions unless monkey.folder TEST_CONFIG[:bootstrap_options][:folder]
end

namespace :test do
  task vsphere: :vmonkey do |t|
    shell_out! %Q{(cd test/chef-repo && chef-client -z -o test::vsphere,test::simple)}
  end

  task :vagrant do |t|
    shell_out! %Q{(cd test/chef-repo && chef-client -z -o test::vagrant,test::simple)}
  end

  task clean: :vmonkey do |t|
    shell_out! %Q{(cd test/chef-repo && chef-client -z -o test::vsphere,test::destroy_all)}
  end

  RSpec::Core::RakeTask.new(:unit) do |rspec|
    rspec.pattern = 'test/unit'
  end

  RSpec::Core::RakeTask.new(integration: :vmonkey) do |rspec|
    rspec.pattern = 'test/integration'
  end
end

desc 'Run RSpec unit tests'
task unit: 'test:unit'

desc 'Run test cookbook with vsphere and RSpec integration tests'
task integration: ['test:vsphere', 'test:integration']

desc 'Run all tests using vsphere driver'
task test: [:unit, 'test:clean', :integration, 'test:clean']
