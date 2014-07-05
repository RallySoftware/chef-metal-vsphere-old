module VmonkeyHelper
  @instructions = "
    For the test coobook to run with the vsphere driver, you need:
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

  def self.config
    yml_path = File.expand_path( ENV['VMONKEY_YML'] )
    YAML::load_file(yml_path).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
  rescue
    raise @instructions
  end
end
