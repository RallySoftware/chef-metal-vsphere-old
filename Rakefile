require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'mixlib/shellout'

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

namespace :test do
  desc 'Run test cookbook in vSphere'
  task :vsphere do |t|
    shell_out! %Q{(cd test && chef-client -z -o test::vsphere,test::simple)}
  end

  desc 'Run test cookbook in vagrant'
  task :vagrant do |t|
    shell_out! %Q{(cd test && chef-client -z -o test::vagrant,test::simple)}
  end

  desc 'Destroy test machines'
  task :clean do |t|
    shell_out! %Q{(cd test && chef-client -z -o test::vsphere,test::destroy_all)}
  end
end