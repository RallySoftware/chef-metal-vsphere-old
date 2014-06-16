require 'chef_metal_vsphere'

with_driver 'vsphere'

with_machine_options :vsphere_options => {
  'template' => '/Templates/c64.medium',
  'folder' => 'Template CI'
}
