require_relative 'spec_helper'

describe ChefMetalVsphere::VsphereDriver do
  describe '::canonicalize_url' do
    let(:vmonkey_config) do
      {
        host: 'spec_host',
        datacenter: 'spec_datacenter',
        cluster: 'spec_cluster'
      }
    end

    before :each do
      allow(VMonkey).to receive(:default_opts) { vmonkey_config }
    end

    subject { described_class::canonicalize_url('vsphere', {}) }

    it { should include('vsphere:spec_host:spec_datacenter:spec_cluster') }
  end
end