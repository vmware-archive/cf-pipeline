require 'minitest/autorun'
require 'json'
require 'rexml/document'
require 'rexml/xpath'

describe 'pipeline support' do
  it 'creates a deploy job for a configured project' do
    assert find_job('garden-deploy'), "Couldn't find expected job. Found these: #{all_jobs.map {|job| job['name']}}"
    expected_command = "cf_deploy --non-interactive --release-name garden --release-repo https://github.com/vito/garden-pool-spike.git --release-ref master --infrastructure warden --deployments-repo https://github.com/cloudfoundry/deployments-foo.git --deployment-name bosh_lite"
    assert_match expected_command, config_for('garden-deploy').shell_command,
      "Shell command was incorrect"
  end

  it 'creates a system test job downstream from the deploy job' do
    downstream_jobs_for('garden-deploy').must_equal ['garden-system_tests']
  end

  it 'creates a release tarball job downstream from the system test job' do
    downstream_jobs_for('garden-system_tests').must_equal ['garden-release_tarball']
  end

  it 'terminates at the release tarball' do
    downstream_jobs_for('garden-release_tarball').must_be_empty
  end

  def all_jobs
    json = curl "#{host}/api/json"
    JSON.parse(json).fetch('jobs')
  end

  def find_job(job_name)
    all_jobs.detect { |job| job.fetch('name') == job_name }
  end

  def config_for(job_name)
    doc = REXML::Document.new(curl("#{host}/job/#{job_name}/config.xml"))
    JobConfig.new(
      REXML::XPath.first(doc, '//builders/hudson.tasks.Shell/command').text
    )
  end

  def downstream_jobs_for(job_name)
    json = curl "#{host}/job/#{job_name}/api/json"
    JSON.parse(json).fetch('downstreamProjects').map do |project|
      project.fetch('name')
    end
  end

  class JobConfig < Struct.new(:shell_command)
  end

  def curl(command)
    `curl --silent #{command}`
  end

  def host
    "http://127.0.0.1:8080"
  end
end

