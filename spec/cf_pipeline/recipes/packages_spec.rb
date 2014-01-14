require 'spec_helper'

describe 'cf_pipeline::packages' do
  subject(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['cf_pipeline']['packages'] = %w(not_a_real_package)
    end.converge(described_recipe)
  end

  it "installs libxml2-dev and libxslt-dev for Nokogiri" do
    expect(chef_run).to install_package('libxml2-dev')
    expect(chef_run).to install_package('libxslt-dev')
  end

  it "installs any packages named in the node attributes" do
    expect(chef_run).to install_package('not_a_real_package')
  end
end
