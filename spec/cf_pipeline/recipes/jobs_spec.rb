require 'spec_helper'

describe 'cf_pipeline::jobs' do
  let(:default_job_settings) do
    {
      'git' => 'https://github.com/org/release.git',
      'git_ref' => 'master',
      'script_path' => './path/to/script.sh',
    }
  end

  let(:job_settings) { default_job_settings }

  let(:jobs) do
    {
      'example_job' => job_settings
    }
  end

  subject(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['jenkins'] = {
        'server' => {
          'home' => fake_jenkins_home
        }
      }
      node.set['cf_pipeline'] = {'jobs' => jobs}
    end.converge(described_recipe)
  end

  let(:fake_jenkins_home) { Dir.mktmpdir }
  let(:fake_chef_rest_for_jenkins_check) { double(Chef::REST::RESTRequest, call: double(Net::HTTPSuccess).as_null_object) }

  let(:job_config_path) { File.join(fake_jenkins_home, 'jobs', 'example_job', 'config.xml') }

  let(:expected_env) { 'PIPELINE_USER_SCRIPT=./path/to/script.sh' }
  let(:expected_command) { 'run_user_script' }

  before do
    FileUtils.mkdir_p(File.dirname(job_config_path))
    FileUtils.touch(job_config_path)

    Chef::REST::RESTRequest.stub(new: fake_chef_rest_for_jenkins_check)
  end

  context 'minimal config' do
    it { should have_job_config_with_content(job_config_path, job_settings) }
  end

  context 'when artifact_glob is specified' do
    let(:job_settings) { default_job_settings.merge('artifact_glob' => 'foo/*.bar') }

    it { should have_job_config_with_content(job_config_path, job_settings) }
  end

  context 'when build_parameters is specified' do
    let(:job_settings) { default_job_settings.merge('build_parameters' => [{'name' => 'FOO'}, {'name' => 'BAR'}]) }

    it { should have_job_config_with_content(job_config_path, job_settings) }
  end

  describe '#block_on_downstream_builds' do
    let(:job_settings) { default_job_settings.merge('block_on_downstream_builds' => block_on_downstream_builds) }

    context 'when true' do
      let(:block_on_downstream_builds) { true }

      it { should have_job_config_with_content(job_config_path, job_settings) }
    end

    context 'when false' do
      let(:block_on_downstream_builds) { false }

      it { should have_job_config_with_content(job_config_path, job_settings) }
    end
  end

  context 'when trigger_on_success is specified' do
    let(:job_settings) { default_job_settings.merge('trigger_on_success' => ['next_job']) }

    it { should have_job_config_with_content(job_config_path, job_settings) }
  end

  context 'when environment is specified' do
    let(:job_settings) { default_job_settings.merge('env' => {'FAKE_ENV' => "fake_env"}) }

    it { should have_job_config_with_content(job_config_path, job_settings) }
  end

  matcher(:have_job_config_with_content) do |job_config_path, job_settings|
    matchers_for = ->(chef_run) {
      [
        ChefSpec::Matchers::ResourceMatcher.new('directory', 'create', ::File.dirname(job_config_path)).with(mode: 0755),
        ChefSpec::Matchers::ResourceMatcher.new('file', 'create', job_config_path).with(
          owner: chef_run.node['jenkins']['server']['user'],
          group: chef_run.node['jenkins']['server']['user'],
          mode: 00644,
        ),
        ChefSpec::Matchers::RenderFileMatcher.new(job_config_path).with_content(
          JenkinsClient::Job.from_config(job_settings).to_xml
        ),
      ]
    }

    match do |chef_run|
      matchers_for[chef_run].all? { |matcher| matcher.matches?(chef_run) } &&
        ChefSpec::Matchers::NotificationsMatcher.new('service[jenkins]').
          to(:restart).delayed.matches?(chef_run.file(job_config_path))
    end

    failure_message_for_should do |chef_run|
      failed_matchers = matchers_for[chef_run].select { |matcher| !matcher.matches?(chef_run) }

      restart_matcher = ChefSpec::Matchers::NotificationsMatcher.new('service[jenkins]').to(:restart).delayed
      failed_matchers << restart_matcher unless restart_matcher.matches?(chef_run.file(job_config_path))

      failed_matchers.map(&:failure_message_for_should).join("\n")
    end

    description do
      "create the expected config.xml for #{::File.basename(job_config_path)}"
    end
  end
end
