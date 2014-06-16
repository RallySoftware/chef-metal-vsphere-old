require 'chef_metal/driver'
require 'chef_metal/machine/windows_machine'
require 'chef_metal/machine/unix_machine'
require 'chef_metal/convergence_strategy/install_msi'
require 'chef_metal/convergence_strategy/install_cached'
require 'chef_metal/transport/winrm'
require 'chef_metal/transport/ssh'
require 'chef_metal_vsphere/version'

module ChefMetalVsphere
  # Provisions machines in VMware vSphere.
  class VsphereDriver < ChefMetal::Driver
  end
end
