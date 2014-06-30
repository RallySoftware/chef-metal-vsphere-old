require_relative 'spec_helper'

describe ChefMetalVsphere::VsphereDriver do
  describe '::canonicalize_url' do
    let(:config) do
      {
        host: 'spec_host',
        datacenter: 'spec_datacenter',
        cluster: 'spec_cluster'
      }
    end
    subject { described_class::canonicalize_url('vsphere', config) }

    it { should include('vsphere:spec_host:spec_datacenter:spec_cluster') }
  end
end