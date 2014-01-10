require 'spec_helper'

describe 'cf_pipeline::cf_deployer' do
  subject(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['cf_pipeline']['cf_deployer_ref'] = 'deadbeef'
    end.converge(described_recipe)
  end

  it 'downloads the package and installs cf_deployer as a gem' do
    expect(Chef::Config[:file_cache_path]).not_to be_nil
    dest_dir = "#{Chef::Config[:file_cache_path]}/cf_deployer"

    expect(chef_run).to sync_git(dest_dir).with(
      repository: 'https://github.com/pivotal-cf-experimental/cf-deployer.git',
      revision: 'deadbeef'
    )

    expect(chef_run).to run_bash('remove old gem files').with(
      code: 'rm -f *.gem',
      cwd: dest_dir
    )

    expect(chef_run).to run_bash('build cf_deployer gem').with(
      code: 'source `which go_and_ruby` && gem build cf_deployer.gemspec',
      cwd: dest_dir
    )

    expect(chef_run).to run_bash('install cf_deployer gem').with(
      code: 'source `which go_and_ruby` && gem install --local cf_deployer-*.gem',
      cwd: dest_dir
    )
  end
end
