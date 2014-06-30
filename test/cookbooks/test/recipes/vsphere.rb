require 'chef_metal_vsphere'

with_driver 'vsphere'

with_machine_options bootstrap_options: {
    template: '/Templates/MyTemplate',
    folder: '/VMs'
  }
