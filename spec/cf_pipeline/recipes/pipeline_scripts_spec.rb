require 'spec_helper'

describe 'cf_pipeline::pipeline_scripts' do
  subject(:chef_run) do
    ChefSpec::Runner.new(step_into: ['cookbook_file']).converge(described_recipe)
  end

  it "creates the go_and_ruby script" do
    expect(chef_run).to create_cookbook_file('go and ruby script').with(
      path: '/usr/local/bin/go_and_ruby',
      mode: '0755',
      source: 'go_and_ruby'
    )
  end

  it "creates a deploy script" do
    expect(chef_run).to create_cookbook_file('deploy script').with(
      path: '/usr/local/bin/pipeline_deploy',
      mode: '0755',
      source: 'pipeline_deploy'
    )
  end

  it "creates a system tests script" do
    expect(chef_run).to create_cookbook_file('system tests script').with(
      path: '/usr/local/bin/test_deployment',
      mode: '0755',
      source: 'test_deployment'
    )
  end

  it "creates a release tarball script" do
    expect(chef_run).to create_cookbook_file('release tarball script').with(
      path: '/usr/local/bin/create_release_tarball',
      mode: '0755',
      source: 'create_release_tarball'
    )
  end
end
