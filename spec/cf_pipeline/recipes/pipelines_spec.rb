require 'spec_helper'

describe 'cf_pipeline::pipelines' do
  let(:default_example_project_config) do
    {
      'git' => 'https://github.com/org/release.git',
      'release_ref' => 'master',
      'infrastructure' => 'warden',
      'deployments_repo' => 'https://github.com/org/deployments.git',
      'deployment_name' => 'my_environment',
    }
  end

  let(:example_project_config_with_name_override) do
    default_example_project_config.merge('release_name' => 'new_release_name')
  end

  let(:example_project_config) { default_example_project_config }
  let(:pipeline_attributes) do
    {
      'pipelines' => {
        'example_project' => example_project_config
      },
      'env' => {
        'IRC_PASSWORD' => 'hunter2',
        'FAVORITE_FOOD' => 'rocks'
      }
    }
  end

  subject(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['jenkins'] = {
        'server' => {
          'home' => fake_jenkins_home
        }
      }
      node.set['cf_pipeline'] = pipeline_attributes
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

  shared_examples "creates the expected jenkins jobs" do
    it { should create_pipeline_jenkins_job('example_project-deploy',
                                            in: fake_jenkins_home,
                                            env: expected_env,
                                            command: "pipeline_deploy") }

    it { should create_pipeline_jenkins_job('example_project-system_tests',
                                            in: fake_jenkins_home,
                                            env: expected_env,
                                            command: "test_deployment") }

    it { should create_pipeline_jenkins_job('example_project-release_tarball',
                                            env: expected_env,
                                            in: fake_jenkins_home,
                                            command: "create_release_tarball") }
  end

  context 'when the release name is not overridden' do
    let(:expected_env) do
      (<<-SH
PIPELINE_RELEASE_NAME=example_project
PIPELINE_RELEASE_REPO=https://github.com/org/release.git
PIPELINE_RELEASE_REF=master
PIPELINE_INFRASTRUCTURE=warden
PIPELINE_DEPLOYMENTS_REPO=https://github.com/org/deployments.git
PIPELINE_DEPLOYMENT_NAME=my_environment
IRC_PASSWORD=hunter2
FAVORITE_FOOD=rocks
      SH
      ).strip
    end

    include_examples "creates the expected jenkins jobs"
  end

  context 'when the release name is overridden' do
    let(:example_project_config) { example_project_config_with_name_override }
    let(:expected_env) do
      (<<-SH
PIPELINE_RELEASE_NAME=new_release_name
PIPELINE_RELEASE_REPO=https://github.com/org/release.git
PIPELINE_RELEASE_REF=master
PIPELINE_INFRASTRUCTURE=warden
PIPELINE_DEPLOYMENTS_REPO=https://github.com/org/deployments.git
PIPELINE_DEPLOYMENT_NAME=my_environment
IRC_PASSWORD=hunter2
FAVORITE_FOOD=rocks
      SH
      ).strip
    end

    include_examples "creates the expected jenkins jobs"
  end

  context 'when env_overrides are specified' do
    before do
      pipeline_attributes['env_overrides'] = {
        'example_project' => {
          'FAVORITE_FOOD' => 'clouds'
        },
        'other_project' => {
          'IRC_PASSWORD' => '*******'
        }
      }
    end

    let(:expected_env) do
      (<<-SH
PIPELINE_RELEASE_NAME=example_project
PIPELINE_RELEASE_REPO=https://github.com/org/release.git
PIPELINE_RELEASE_REF=master
PIPELINE_INFRASTRUCTURE=warden
PIPELINE_DEPLOYMENTS_REPO=https://github.com/org/deployments.git
PIPELINE_DEPLOYMENT_NAME=my_environment
IRC_PASSWORD=hunter2
FAVORITE_FOOD=clouds
      SH
      ).strip
    end

    include_examples "creates the expected jenkins jobs"
  end

  it { should archive_artifacts('dev_releases/*.tgz',
                                in: fake_jenkins_home,
                                project: 'example_project-release_tarball') }

  matcher(:create_pipeline_jenkins_job) do |expected_job_name, options|
    job_directory = ::File.join(options.fetch(:in), 'jobs', expected_job_name)
    config_path = ::File.join(job_directory, 'config.xml')

    matchers_for = ->(chef_run) {
      jenkins_user = jenkins_group = chef_run.node['jenkins']['server']['user']
      [
        ChefSpec::Matchers::ResourceMatcher.new('directory', 'create', job_directory).with(mode: 0755),
        ChefSpec::Matchers::ResourceMatcher.new('file', 'create', config_path).with(
          owner: jenkins_user,
          group: jenkins_group,
          mode: 00644,
        ),
        ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(options.fetch(:env)),
        ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(options.fetch(:command)),
      ]
    }

    match do |chef_run|
      matchers_for[chef_run].all? { |matcher| matcher.matches?(chef_run) } &&
        ChefSpec::Matchers::NotificationsMatcher.new('service[jenkins]').to(:restart).delayed.
          matches?(chef_run.file(config_path))
    end

    failure_message_for_should do |chef_run|
      restart_matcher = ChefSpec::Matchers::NotificationsMatcher.new('service[jenkins]').to(:restart).delayed
      failed_matcher = matchers_for[chef_run].find { |matcher| !matcher.matches?(chef_run) }
      failed_matcher ||= restart_matcher unless restart_matcher.matches?(chef_run.file(config_path))

      failed_matcher.failure_message_for_should
    end

    description do
      "create a pipeline jenkins job for #{expected_job_name}"
    end
  end

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
end
