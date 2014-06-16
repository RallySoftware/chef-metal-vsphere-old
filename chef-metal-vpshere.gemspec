# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef_metal_vsphere/version'

Gem::Specification.new do |spec|
  spec.name             = 'chef-metal-vsphere'
  spec.version          = ChefMetalVsphere::VERSION
  spec.platform         = Gem::Platform::RUBY
  spec.authors          = ['Brian Dupras']
  spec.email            = ['brian@duprasville.com']
  spec.summary          = %q{chef-metal vSphere driver}
  spec.description      = spec.summary
  spec.homepage         = 'https://github.com/vmtricks/chef-metal-vsphere'
  spec.license          = 'MIT'

  spec.require_path     = 'lib'
  spec.files            = `git ls-files -z`.split("\x0")
  spec.extra_rdoc_files = ['README.md', 'LICENSE.txt' ]
  spec.bindir           = 'bin'
  spec.executables      = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files       = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths    = ['lib']

  spec.add_dependency 'chef', '~> 11.12'
  spec.add_dependency 'chef-metal', '~> 0.11'
  spec.add_dependency 'vmonkey', '~> 0.1'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'mixlib-shellout', '~> 1.4.0'
  spec.add_development_dependency 'chef-metal-vagrant', '~> 0.4'
end
