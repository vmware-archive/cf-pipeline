require 'minitest/autorun'
require 'tmpdir'
require_relative 'test_helper'

describe "test_deployment script" do
  it "calls script/run_system_tests" do
    in_tmp_dir do
      create_git_project_with_submodules('project')
      Dir.chdir('project') do
        FileUtils.mkdir 'script'
        write_fake_system_test_script('script/run_system_tests')

        system('test_deployment > out')
        assert_git_updated_recursive_submodules

        assert_equal "Hello from system tests", File.read('out').strip.split("\n").last
      end
    end
  end

  def write_fake_system_test_script(path)
    File.open(path, 'w') do |file|
      file << <<-'EOF'
#!/usr/bin/env ruby

puts 'Hello from system tests'
      EOF
    end

    FileUtils.chmod 0755, path
  end
end
