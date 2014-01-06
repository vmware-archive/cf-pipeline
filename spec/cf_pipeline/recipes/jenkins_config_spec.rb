require 'spec_helper'

describe 'cf_pipeline::jenkins_config' do
  subject(:chef_run) do
    ChefSpec::Runner.new(step_into: ['jenkins_job']) do |node|
      node.set['jenkins'] = {
        'server' => {
          'home' => fake_jenkins_home
        }
      }

      node.set['cf_pipeline']['github_oauth'] = {
        'organization' => 'my-org',
        'admins' => ['octocat'],
        'client_id' => 'the_client_id',
        'client_secret' => 'the_client_secret'
      }
    end.converge(described_recipe)
  end

  let(:jenkins_user) { chef_run.node['jenkins']['server']['user'] }
  let(:jenkins_group) { jenkins_user }
  let(:fake_jenkins_home) { Dir.mktmpdir }
  let(:jenkins_config_path) { File.join(fake_jenkins_home, 'config.xml') }

  before do
    FileUtils.mkdir_p(File.dirname(jenkins_config_path))
    FileUtils.touch(jenkins_config_path)
  end

  it 'creates the jenkins configuration file' do
    vars = {
      'github_user_org' => 'my-org',
      'github_user_admins' => ['octocat'],
      'github_client_id' => 'the_client_id',
      'github_client_secret' => 'the_client_secret'
    }
    expect(chef_run).to create_template(jenkins_config_path).
      with(source: 'jenkins_config.xml.erb',
           owner: jenkins_user,
           group: jenkins_group,
           mode: 00644,
           variables: vars)
  end
end
