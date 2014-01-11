require 'spec_helper'

describe 'cf_pipeline::packages' do
  subject(:chef_run) do
    ChefSpec::Runner.new do |node|
    end.converge(described_recipe)
  end

  it "installs libxml2-dev and libxslt-dev for Nokogiri" do
    expect(chef_run).to install_package('libxml2-dev')
    expect(chef_run).to install_package('libxslt-dev')
  end
end
