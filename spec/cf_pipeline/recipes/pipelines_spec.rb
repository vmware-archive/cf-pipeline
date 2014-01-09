require 'spec_helper'

describe 'cf_pipeline::pipelines' do
  subject(:chef_run) do
    ChefSpec::Runner.new(step_into: ['jenkins_job']) do |node|
      node.set['jenkins'] = {
        'server' => {
          'home' => fake_jenkins_home
        }
      }
      node.set['cf_pipeline'] = {
        'pipelines' => {
          'example_project' => {
            'git' => 'https://github.com/org/release.git',
            'release_ref' => 'master',
            'infrastructure' => 'warden',
            'deployments_repo' => 'https://github.com/org/deployments.git',
            'deployment_name' => 'my_environment',
          }
        }
      }
    end.converge(described_recipe)
  end

  let(:fake_jenkins_home) { Dir.mktmpdir }
  let(:deploy_job_config) { File.join(fake_jenkins_home, 'jobs', 'example_project-deploy', 'config.xml') }
  let(:tests_job_config) { File.join(fake_jenkins_home, 'jobs', 'example_project-system_tests', 'config.xml') }
  let(:release_job_config) { File.join(fake_jenkins_home, 'jobs', 'example_project-release_tarball', 'config.xml') }
  let(:fake_chef_rest_for_jenkins_check) { double(Chef::REST::RESTRequest, call: double(Net::HTTPSuccess).as_null_object) }

  before do
    FileUtils.mkdir_p(File.dirname(deploy_job_config))
    FileUtils.touch(deploy_job_config)

    FileUtils.mkdir_p(File.dirname(tests_job_config))
    FileUtils.touch(tests_job_config)

    FileUtils.mkdir_p(File.dirname(release_job_config))
    FileUtils.touch(release_job_config)

    Chef::REST::RESTRequest.stub(new: fake_chef_rest_for_jenkins_check)
  end

  matcher(:create_jenkins_job) do |expected_job_name, options|
    job_directory = ::File.join(options.fetch(:in), 'jobs', expected_job_name)
    config_path = ::File.join(job_directory, 'config.xml')

    command_for = ->(sub_command) {
      <<-BASH
#!/bin/bash

#{sub_command}
      BASH
    }

    matchers_for = ->(chef_run) {
      jenkins_user = jenkins_group = chef_run.node['jenkins']['server']['user']
      [
        ChefSpec::Matchers::ResourceMatcher.new('directory', 'create', job_directory).with(mode: 0755),
        ChefSpec::Matchers::ResourceMatcher.new('file', 'create', config_path).with(
          owner: jenkins_user,
          group: jenkins_group,
          mode: 00644,
        ),
        ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(options.fetch(:env)), # if env????
        ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(command_for[options.fetch(:command)]),
      ]
    }

    match do |chef_run|
      matchers_for[chef_run].all? {|matcher| matcher.matches?(chef_run)} &&
        ChefSpec::Matchers::NotificationsMatcher.new('service[jenkins]').to(:restart).delayed.
        matches?(chef_run.file(config_path))
    end

    failure_message_for_should do |chef_run|
      restart_matcher = ChefSpec::Matchers::NotificationsMatcher.new('service[jenkins]').to(:restart).delayed
      failed_matcher = matchers_for[chef_run].find {|matcher| !matcher.matches?(chef_run)}
      failed_matcher ||= restart_matcher unless restart_matcher.matches?(chef_run.file(config_path))

      failed_matcher.failure_message_for_should
    end

    description do
      "create a pipeline jenkins job for #{expected_job_name}"
    end
  end

  let(:expected_env) do
    (<<-SH
RELEASE_NAME=example_project
RELEASE_REPO=https://github.com/org/release.git
RELEASE_REF=master
INFRASTRUCTURE=warden
DEPLOYMENTS_REPO=https://github.com/org/deployments.git
DEPLOYMENT_NAME=my_environment
    SH
    ).strip
  end

  it { should create_jenkins_job('example_project-deploy',
                                 in: fake_jenkins_home,
                                 env: expected_env,
                                 command: "pipeline_deploy") }

  it { should create_jenkins_job('example_project-system_tests',
                                 in: fake_jenkins_home,
                                 env: expected_env,
                                 command: "test_deployment" ) }

  it { should create_jenkins_job('example_project-release_tarball',
                                 env: expected_env,
                                 in: fake_jenkins_home,
                                 command: "create_release_tarball" ) }

  matcher(:archive_artifacts) do |glob, options|
    job_directory = ::File.join(options.fetch(:in), 'jobs', options.fetch(:project))
    config_path = ::File.join(job_directory, 'config.xml')
    matcher = ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(glob)

    match do |chef_run|
      matcher.matches?(chef_run)
    end

    failure_message_for_should do |chef_run|
      matcher.failure_message_for_should
    end

    description { "archive artifacts with glob #{glob} in #{options.fetch(:project)}" }
  end

  it { should archive_artifacts('dev_releases/*.tgz',
                                in: fake_jenkins_home,
                                project: 'example_project-release_tarball') }
end
