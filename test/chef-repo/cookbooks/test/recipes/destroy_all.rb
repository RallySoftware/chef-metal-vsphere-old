require 'chef_metal'

Chef::Log.warn "Destroy machines [#{search(:node, '*:*').map { |n| n.name }}]"

machine_batch do
  machines search(:node, '*:*').map { |n| n.name }
  action :destroy
end