require 'spec_helper'
require_relative '../../libraries/job'
require 'nokogiri'

describe JenkinsClient::Job do
  describe "by default" do
    subject { JenkinsClient::Job.new.to_xml }
    it { should have_no_downstream_jobs }
    it { should have_no_artifact_glob }
    it { should have_color_output }
  end

  it 'serializes the description' do
    job = JenkinsClient::Job.new
    job.description = "Best job ever"

    xml = job.to_xml
    doc = Nokogiri::XML(xml)
    expect(doc.xpath('//project/description').text).to eq('Best job ever')
  end

  it 'serializes the git SCM config' do
    job = JenkinsClient::Job.new
    job.git_repo_url = "https://github.com/org/repo"
    job.git_repo_branch = "master"

    expect(job.to_xml).to have_git_repo_url('https://github.com/org/repo')
    expect(job.to_xml).to have_git_repo_branch('master')
  end

  it 'serializes the command' do
    job = JenkinsClient::Job.new
    job.command = 'release-the-hounds'

    expect(job.to_xml).to have_command('release-the-hounds')
  end

  it 'serializes the downstream jobs' do
    job = JenkinsClient::Job.new
    job.downstream_jobs = ['other-project', 'different-project']

    expect(job.to_xml).to have_downstream_jobs(['other-project', 'different-project'])
  end

  it 'archives artifacts when a glob is given' do
    job = JenkinsClient::Job.new
    job.artifact_glob = "dev_releases/*.tgz"

    expect(job.to_xml).to have_artifact_glob("dev_releases/*.tgz")
  end

  it 'has a standard set of environment variables' do
    job = JenkinsClient::Job.new
    job.env = {
      'RELEASE_NAME' => 'my_release_name',
      'RELEASE_REPO' => 'my_release_repo',
      'RELEASE_REF' => 'my_release_ref',
      'INFRASTRUCTURE' => 'my_infrastructure',
      'DEPLOYMENTS_REPO' => 'my_deployments_repo',
      'DEPLOYMENT_NAME' => 'my_deployment_name',
    }

    expect(job.to_xml).to have_environment_variables <<-SH
RELEASE_NAME=my_release_name
RELEASE_REPO=my_release_repo
RELEASE_REF=my_release_ref
INFRASTRUCTURE=my_infrastructure
DEPLOYMENTS_REPO=my_deployments_repo
DEPLOYMENT_NAME=my_deployment_name
    SH
  end

  matcher(:have_environment_variables) do |shell_vars|
    match do |xml|
      doc = Nokogiri::XML(xml)
      doc.xpath('//buildWrappers/EnvInjectBuildWrapper/info/propertiesContent').text == shell_vars.strip
    end

    failure_message_for_should do |xml|
      "Expected to find the following shell vars:\n#{shell_vars}\nin the following XML:\n#{xml}"
    end
  end

  matcher(:have_color_output) do
    match do |xml|
      doc = Nokogiri::XML(xml)
      doc.xpath('//buildWrappers/hudson.plugins.ansicolor.AnsiColorBuildWrapper/colorMapName').text == 'xterm'
    end

    failure_message_for_should do |xml|
      "Expected to find an xterm color build wrapper, but didn't:\n#{xml}"
    end
  end

  matcher(:have_git_repo_url) do |expected_url|
    match do |xml|
      doc = Nokogiri::XML(xml)
      doc.xpath('//scm[@class="hudson.plugins.git.GitSCM"]').first['plugin'] == "git@2.0" &&
        doc.xpath('//scm/userRemoteConfigs/hudson.plugins.git.UserRemoteConfig/url').text == expected_url
    end

    failure_message_for_should do |xml|
      "Expected to find git repo URL #{expected_url} in:\n#{xml}"
    end
  end

  matcher(:have_git_repo_branch) do |expected_branch_name|
    match do |xml|
      doc = Nokogiri::XML(xml)
      doc.xpath('//scm[@class="hudson.plugins.git.GitSCM"]').first['plugin'] == "git@2.0" &&
        doc.xpath('//scm/branches/hudson.plugins.git.BranchSpec/name').text == expected_branch_name
    end

    failure_message_for_should do |xml|
      "Expected to find git repo branch name #{expected_branch_name} in:\n#{xml}"
    end
  end

  matcher(:have_command) do |expected_command|
    match do |xml|
      doc = Nokogiri::XML(xml)
      doc.xpath('//builders/hudson.tasks.Shell/command').text == expected_command
    end

    failure_message_for_should do |xml|
      "Expected to find command #{expected_command} in:\n#{xml}"
    end
  end

  matcher(:have_downstream_jobs) do |expected_project_names|
    match do |xml|
      doc = Nokogiri::XML(xml)
      xpath = '//publishers/hudson.plugins.parameterizedtrigger.BuildTrigger/configs/hudson.plugins.parameterizedtrigger.BuildTriggerConfig/projects'
      doc.xpath(xpath).first.text.split(", ").sort == expected_project_names.sort
    end

    failure_message_for_should do |xml|
      "Expected to find downstream jobs #{expected_project_names.join(', ')} in:\n#{xml}"
    end
  end

  matcher(:have_no_downstream_jobs) do
    match do |xml|
      doc = Nokogiri::XML(xml)
      xpath = '//publishers/hudson.plugins.parameterizedtrigger.BuildTrigger/configs/hudson.plugins.parameterizedtrigger.BuildTriggerConfig/projects'
      doc.xpath(xpath).empty?
    end

    failure_message_for_should do |xml|
      "Expected to find no downstream jobs in:\n#{xml}"
    end
  end

  matcher(:have_artifact_glob) do |expected_glob|
    match do |xml|
      doc = Nokogiri::XML(xml)
      xpath = '//publishers/hudson.tasks.ArtifactArchiver/artifacts'
      doc.xpath(xpath).text == expected_glob
    end
  end

  matcher(:have_no_artifact_glob) do
    match do |xml|
      doc = Nokogiri::XML(xml)
      xpath = '//publishers/hudson.tasks.ArtifactArchiver/artifacts'
      doc.xpath(xpath).empty?
    end
  end
end
