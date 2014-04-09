require 'spec_helper'

describe 'cf_pipeline::jobs' do
  let(:default_job_config) do
    {
      'git' => 'https://github.com/org/release.git',
      'git_ref' => 'master',
      'script_path' => './path/to/script.sh',
    }
  end

  let(:job_config) { default_job_config }

  let(:job_attributes) do
    {
      'jobs' => {
        'example_job' => job_config
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
      node.set['cf_pipeline'] = job_attributes
    end.converge(described_recipe)
  end

  let(:fake_jenkins_home) { Dir.mktmpdir }
  let(:job_config_path) { File.join(fake_jenkins_home, 'jobs', 'example_job', 'config.xml') }
  let(:fake_chef_rest_for_jenkins_check) { double(Chef::REST::RESTRequest, call: double(Net::HTTPSuccess).as_null_object) }

  let(:expected_env) { 'PIPELINE_USER_SCRIPT=./path/to/script.sh' }
  let(:expected_command) { 'run_user_script' }

  before do
    FileUtils.mkdir_p(File.dirname(job_config_path))
    FileUtils.touch(job_config_path)

    Chef::REST::RESTRequest.stub(new: fake_chef_rest_for_jenkins_check)
  end


  context 'minimal config' do
    it { should create_user_jenkins_job('example_job',
                                        in: fake_jenkins_home,
                                        env: expected_env,
                                        downstream: [],
                                        command: expected_command) }
  end

  context 'when artifact_glob is specified' do
    let(:job_config) do
      config = default_job_config.dup
      config['artifact_glob'] = 'foo/*.bar'
      config
    end

    it { should create_user_jenkins_job('example_job',
                                        in: fake_jenkins_home,
                                        env: expected_env,
                                        artifact_glob: 'foo/*.bar',
                                        downstream: [],
                                        command: expected_command) }
  end

  context 'when build_parameters is specified' do
    let(:job_config) do
      config = default_job_config.dup
      config['build_parameters'] = [{'name' => 'FOO'}, {'name' => 'BAR'}]
      config
    end

    it { should create_user_jenkins_job('example_job',
                                        in: fake_jenkins_home,
                                        env: expected_env,
                                        build_parameters: ['FOO', 'BAR'],
                                        downstream: [],
                                        command: expected_command) }
  end

  describe '#block_on_downstream_builds' do
    let(:job_config) do
      default_job_config.merge('block_on_downstream_builds' => block_on_downstream_builds)
    end

    context 'when true' do
      let(:block_on_downstream_builds) { true }

      it { should create_user_jenkins_job('example_job',
                                          in: fake_jenkins_home,
                                          env: expected_env,
                                          block_on_downstream_builds: true,
                                          downstream: [],
                                          command: expected_command) }
    end

    context 'when false' do
      let(:block_on_downstream_builds) { false }

      it { should create_user_jenkins_job('example_job',
                                          in: fake_jenkins_home,
                                          env: expected_env,
                                          block_on_downstream_builds: false,
                                          downstream: [],
                                          command: expected_command) }
    end
  end

  context 'when trigger_on_success is specified' do
    let(:job_config) do
      config = default_job_config.dup
      config['trigger_on_success'] = ['next_job']
      config
    end

    it { should create_user_jenkins_job('example_job',
                                        in: fake_jenkins_home,
                                        env: expected_env,
                                        downstream: ['next_job'],
                                        command: expected_command) }
  end

  context 'when environment is specified' do
    let(:job_config) do
      config = default_job_config.dup
      config['env'] = {'FAKE_ENV' => "fake_env"}
      config
    end

    let(:expected_env) { "PIPELINE_USER_SCRIPT=./path/to/script.sh\nFAKE_ENV=fake_env" }

    it { should create_user_jenkins_job('example_job',
                                        in: fake_jenkins_home,
                                        env: expected_env,
                                        downstream: [],
                                        command: expected_command) }
  end

  matcher(:create_user_jenkins_job) do |expected_job_name, options|
    job_directory = ::File.join(options.fetch(:in), 'jobs', expected_job_name)
    config_path = ::File.join(job_directory, 'config.xml')

    matchers_for = ->(chef_run) {
      jenkins_user = jenkins_group = chef_run.node['jenkins']['server']['user']
      build_params_matchers =
        options.fetch(:build_parameters, []).map do |bp|
          ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(bp)
        end
      block_on_downstream_builds =
        "<blockBuildWhenDownstreamBuilding>#{options.fetch(:block_on_downstream_builds, false)}</blockBuildWhenDownstreamBuilding>"

      [
        ChefSpec::Matchers::ResourceMatcher.new('directory', 'create', job_directory).with(mode: 0755),
        ChefSpec::Matchers::ResourceMatcher.new('file', 'create', config_path).with(
          owner: jenkins_user,
          group: jenkins_group,
          mode: 00644,
        ),
        ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(options.fetch(:env)),
        ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(options.fetch(:command)),
        ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(options.fetch(:artifact_glob, '')),
        ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(options.fetch(:downstream).join(', ')),
        *build_params_matchers,
        ChefSpec::Matchers::RenderFileMatcher.new(config_path).with_content(block_on_downstream_builds),
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
      "create a user-jenkins-job for #{expected_job_name}"
    end
  end
end
