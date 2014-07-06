require 'serverspec'
require 'net/ssh'
require 'vmonkey'
require 'rspec/its'

ENV['VMONKEY_YML'] ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '.vmonkey'))
instructions = "TODO - instructions here"
begin
  File.read ENV['VMONKEY_YML']
rescue => e
  puts instructions
  raise e
end

def monkey
  @monkey ||= VMonkey.connect
end

TEST_CONFIG = monkey.opts[:test]
fail instructions unless TEST_CONFIG
fail instructions unless TEST_CONFIG[:ssh_options]
fail instructions unless TEST_CONFIG[:ssh_options][:password]
fail instructions unless TEST_CONFIG[:bootstrap_options]
fail instructions unless monkey.folder TEST_CONFIG[:bootstrap_options][:folder]

include Specinfra::Helper::Ssh
include Specinfra::Helper::DetectOS

def serverspec_vm(vm_name)
  vm = monkey.vm! "/#{TEST_CONFIG[:bootstrap_options][:folder]}/#{vm_name}"
  host = vm.guest_ip

  options = TEST_CONFIG[:ssh_options]
  options[:user] ||= 'root'

  set :host, host
  set :ssh_options, options

  vm
end