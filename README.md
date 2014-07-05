chef-metal-vsphere
==================

This is a [chef-metal](https://github.com/opscode/chef-metal) provisioner for [VMware vSphere](http://www.vmware.com/products/vsphere).

Currently, chef-metal-vsphere supports provisioning Unix/ssh guest VMs.

Try It Out
----------

### vSphere VM Template

Create or obtain a unix/linux VM template.  The VM template must:

  - be capable of installing Chef 11.8 or newer
  - run vmware-tools on system boot (provides visiblity to ip address of the running VM)
  - provide access via ssh
  - provide a user account with NOPASSWD sudo


### vSphere Credentials
Create a file called $HOME/.vmonkey.  chef-metal-vsphere uses [vmonkey](https://github.com/vmtricks/vmonkey) to connect to vSphere.  

    host: vcenter_host_name
    user: vcenter_user_name
    password: your_mothers_maiden_name
    datacenter: datacenter_name
    cluster: cluster_name
    insecure: true
    ssl: true


### Example recipe
    require 'chef_metal_vsphere'
    with_driver 'vsphere'

    with_machine_options({
      bootstrap_options: {
        template: '/path/to/a/vm/template',           # vCenter "VMs and Templates" path to a VM Template
        folder: '/path/to/a/folder/to/place/new/vms'  # vCenter "VMs and Templates" path to a Folder.  New VMs are created in this folder.
      },
      ssh_options: {
        user:                  'root',                # root or a user with ssh access and NOPASSWD sudo on a VM cloned from the template
        password:              'your_first_pet',      # consisder using chef-vault
        port:                  22,
        user_known_hosts_file: '/dev/null',           # don't do this in production
        paranoid:              false                  # don't do this in production, either
      }
    })

    1.upto 2 do |n|
      machine "metal_#{n}" do
        action [:create]
      end

      machine "metal_#{n}" do
        action [:stop]
      end

      machine "metal_#{n}" do
        # note: no need to :stop before :delete
        action [:delete]
      end

    end

This will clone your VM template to create two VMware Virtual Machines, "metal_1" and "metal_2", in the vSphere Folder specified by bootstrap_options => folder, bootstrapped to an empty runlist.  It will then stop (guest shutdown) and delete the VMs.

Roadmap
-------

Check out [TODO.md](TODO.md)

Bugs and Contact
----------------

Please submit bugs at [chef-metal-vpshere](https://github.com/vmtricks/chef-metal-vsphere), contact Brian Dupras on Twitter at @briandupras, email at brian@duprasville.com.
