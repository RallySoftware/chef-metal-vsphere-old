require 'chef_metal_vsphere'

with_driver 'vsphere'

with_machine_options({
  bootstrap_options: {
    template: '/Templates/c64.medium',
    folder: '/Template CI'
  },
  ssh_options: {
    user:                  'root',
    password:              'root-pa$$word',
    port:                  22,
    user_known_hosts_file: '/dev/null',
    paranoid:              false
  }
})