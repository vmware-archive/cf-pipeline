require 'spec_helper'

describe 'cf_pipeline::jenkins_config' do
  subject(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['jenkins'] = {
        'server' => {
          'home' => fake_jenkins_home
        }
      }

      node.set['cf_pipeline']['github_oauth'] = oauth_config
    end.converge(described_recipe)
  end

  let(:oauth_config) do
    {
      'organization' => 'my-org',
      'admins' => ['octocat'],
      'client_id' => 'the_client_id',
      'client_secret' => 'the_client_secret'
    }
  end
  let(:jenkins_user) { chef_run.node['jenkins']['server']['user'] }
  let(:jenkins_group) { jenkins_user }
  let(:fake_jenkins_home) { Dir.mktmpdir }
  let(:jenkins_config_path) { File.join(fake_jenkins_home, 'config.xml') }

  before do
    FileUtils.mkdir_p(File.dirname(jenkins_config_path))
    FileUtils.touch(jenkins_config_path)
  end

  it 'restarts Jenkins because it is modifying the config file' do
    resource = chef_run.template(jenkins_config_path)
    expect(resource).to notify('service[jenkins]').to(:restart)
  end

  it 'creates the Jenkins configuration file, with security enabled by default' do
    vars = {
      'use_security' => true,
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

  context 'when security is disabled by the client' do
    let(:oauth_config) do
      {
        'enable' => false,
        'organization' => 'my-org',
        'admins' => ['octocat'],
        'client_id' => 'the_client_id',
        'client_secret' => 'the_client_secret'
      }
    end

    it 'passes the flag to the template' do
      vars = {
        'use_security' => false,
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
end
