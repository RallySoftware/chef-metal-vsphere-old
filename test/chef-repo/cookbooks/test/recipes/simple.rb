require 'chef_metal'

machine 'mario' do
  tag 'itsa_me'
  converge true

  add_machine_options(bootstrap_options: {
      annotation: 'Annotation from recipe.  Woot.'
      })
end

machine_file '/tmp/hello_world' do
  machine 'mario'
  content 'Hello world'
end