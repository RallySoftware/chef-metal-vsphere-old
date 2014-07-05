require 'chef_metal_vsphere'
config = VmonkeyHelper.config

with_driver 'vsphere'

with_machine_options({
  bootstrap_options: {
    template: config[:test][:bootstrap_options][:template],
    folder:   config[:test][:bootstrap_options][:folder]
  },
  ssh_options: {
    user:                  'root',
    password:              config[:test][:ssh_options][:password],
    port:                  22,
    user_known_hosts_file: '/dev/null',
    paranoid:              false
  }
})
