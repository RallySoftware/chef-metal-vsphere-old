require 'chef_metal_vagrant'
test_dir = File.expand_path('../../../../..', File.dirname(__FILE__))
with_driver "vagrant:#{test_dir}/.vagrant"

vagrant_box 'precise64' do
  url 'http://files.vagrantup.com/precise64.box'
end

with_machine_options :vagrant_options => {
  'vm.box' => 'precise64'
}
