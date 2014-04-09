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

  describe '#build_parameters' do
    context 'when NOT set' do
      it 'serializes the build parameters' do
        job = JenkinsClient::Job.new

        doc = Nokogiri::XML(job.to_xml)
        expect(doc.xpath('//project/properties')).to be_empty
      end
    end

    context 'when set' do
      it 'serializes the build parameters' do
        build_params = [
          {'name' =>  'FOO', 'description' =>  'All about Foo'},
          {'name' => 'COWGIRL', 'description' => 'A creamery'},
        ]
        job = JenkinsClient::Job.new
        job.build_parameters = build_params

        expect(job.to_xml).to have_build_parameters(build_params)
      end
    end
  end

  describe '#block_on_downstream_builds' do
    context 'when true' do
      it 'sets blockBuildWhenDownstreamBuilding to true' do
        job = JenkinsClient::Job.new
        job.block_on_downstream_builds = true

        doc = Nokogiri::XML(job.to_xml)
        expect(doc.xpath('//project/blockBuildWhenDownstreamBuilding').text).to eq('true')
      end
    end

    context 'when false' do
      it 'sets blockBuildWhenDownstreamBuilding to false' do
        job = JenkinsClient::Job.new
        job.block_on_downstream_builds = false

        doc = Nokogiri::XML(job.to_xml)
        expect(doc.xpath('//project/blockBuildWhenDownstreamBuilding').text).to eq('false')
      end
    end

    context 'when not set' do
      it 'sets blockBuildWhenDownstreamBuilding to false' do
        job = JenkinsClient::Job.new

        doc = Nokogiri::XML(job.to_xml)
        expect(doc.xpath('//project/blockBuildWhenDownstreamBuilding').text).to eq('false')
      end
    end
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
    job.downstream_jobs = [
      'other-project',
      {
        'name' => 'param-project',
        'parameters' => 'FOO=bar',
      }
    ]

    expect(job.to_xml).to have_downstream_jobs(['other-project', 'param-project'])
  end

  it 'sets parameters as CDATA for downstream jobs' do
    job = JenkinsClient::Job.new
    job.downstream_jobs = [
      'other-project',
      {
        'name' => 'param-project',
        'parameters' => 'FOO=bar',
      }
    ]

    expect(job.to_xml).to have_downstream_job_with_parameter('param-project', 'FOO=bar')
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

  matcher(:have_build_parameters) do |build_parameters|
    match do |xml|
      doc = Nokogiri::XML(xml)

      xpath_base = '//properties/hudson.model.ParametersDefinitionProperty/parameterDefinitions/hudson.model.StringParameterDefinition'
      doc.xpath("#{xpath_base}/name").map{|node| node.text}.sort == build_parameters.map{|bp| bp['name']}.sort &&
        doc.xpath("#{xpath_base}/description").map{|node| node.text}.sort == build_parameters.map{|bp| bp['description']}.sort
    end

    failure_message_for_should do |xml|
      "Expected to find downstream jobs '#{build_parameters.join(', ')}'in:\n#{Nokogiri::XML(xml).to_xml(indent: 2)}"
    end
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
      doc.xpath(xpath).map{|node| node.text}.sort == expected_project_names.sort
    end

    failure_message_for_should do |xml|
      "Expected to find downstream jobs #{expected_project_names.join(', ')} in:\n#{xml}"
    end
  end

  matcher(:have_downstream_job_with_parameter) do |downstream_job, parameter|
    match do |xml|
      doc = Nokogiri::XML(xml)
      xpath_base = '//publishers/hudson.plugins.parameterizedtrigger.BuildTrigger/configs/hudson.plugins.parameterizedtrigger.BuildTriggerConfig'
      doc.xpath("#{xpath_base}/projects").map{|node| node.text}.include?(downstream_job) &&
        doc.xpath("#{xpath_base}/configs/hudson.plugins.parameterizedtrigger.PredefinedBuildParameters/properties").children.select(&:cdata?).first.text == parameter
    end

    failure_message_for_should do |xml|
      "Expected to find downstream jobs '#{downstream_job}', and parameter #{parameter} in:\n#{Nokogiri::XML(xml).to_xml(indent: 2)}"
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
