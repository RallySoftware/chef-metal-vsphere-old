require 'chef_metal'

machine 'mario' do
  tag 'itsa_me'
  converge true
end

machine_file '/tmp/hello_world' do
  machine 'mario'
  content 'Hello world'
end