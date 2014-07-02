require 'chef_metal_vsphere'
config = VmonkeyHelper.config

with_driver 'vsphere'

with_machine_options({
  bootstrap_options: {
    template: config[:test][:template_path],
    folder: config[:test][:working_folder]
  },
  ssh_options: {
    user:                  'root',
    password:              config[:test][:root_password],
    port:                  22,
    user_known_hosts_file: '/dev/null',
    paranoid:              false
  }
})
