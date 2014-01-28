require 'minitest/autorun'
require_relative 'test_helper'

describe 'pipeline support' do
  it 'creates a deploy job for a configured project' do
    assert JenkinsHelper.find_job('garden-deploy'), "Couldn't find expected job. Found these: #{JenkinsHelper.all_jobs.map {|job| job['name']}}"
    expected_command = "pipeline_deploy"
    assert_match expected_command, JenkinsHelper.config_for('garden-deploy').shell_command,
      "Shell command was incorrect"
  end

  it 'creates a system test job downstream from the deploy job' do
    JenkinsHelper.downstream_jobs_for('garden-deploy').must_equal ['garden-system_tests']
  end

  it 'creates a release tarball job downstream from the system test job' do
    JenkinsHelper.downstream_jobs_for('garden-system_tests').must_equal ['garden-release_tarball']
  end

  it 'terminates at the release tarball' do
    JenkinsHelper.downstream_jobs_for('garden-release_tarball').must_be_empty
  end
end

