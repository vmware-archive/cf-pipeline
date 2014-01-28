require 'minitest/autorun'
require_relative 'test_helper'

describe 'job triggers' do
  it 'respects the trigger_on_success property' do
    JenkinsHelper.downstream_jobs_for('first').must_equal ['second']
  end
end

