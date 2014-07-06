require_relative 'spec_helper'

def mario
  @mario ||= serverspec_vm('mario')
end

describe mario do
  its(:name) { should == 'mario' }

  # describe mario.config do
  #   its(:annotation) { should == 'Created by simple.rb.  Woot.' }
  # end

  describe command 'pwd' do
    its(:exit_status) { should == 0 }
  end

  describe file '/tmp/hello_world' do
    its(:content) { should match 'Hello world' }
  end
end