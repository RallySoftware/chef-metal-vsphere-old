module VmonkeyHelper
  @instructions = "
    For the test coobook to run with the vsphere driver, you need:
      - On the machine running the specs:
        + #{ENV['VMONKEY_YML']} (see below)

      - On your vSphere system
        + A VM or Template from which VMs will be cloned (:template_path)
          (Clones of this VM must provide SSH port 22 with root password authentication)
        + A working Folder into which VMs will be cloned (:working_folder)

    Place the following in #{ENV['VMONKEY_YML']}
      host: host_name_or_ip_address
      user: user_name
      password: password
      insecure: true
      ssl: true
      datacenter: datacenter_name
      cluster: cluster_name
      test:
        :root_password: your-root-pa$$word
        :template_path: /path/to/a/vm_or_template
        :working_folder: /path/to/a/folder
    "

  def self.config
    yml_path = File.expand_path( ENV['VMONKEY_YML'] )
    YAML::load_file(yml_path).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
  rescue
    raise @instructions
  end
end
