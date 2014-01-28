require 'minitest/autorun'
require 'tmpdir'
require_relative 'test_helper'

describe "run_user_script script" do
  it "calls $PIPELINE_USER_SCRIPT" do
    in_tmp_dir do
      create_git_project_with_submodules('project')
      Dir.chdir('project') do
        write_fake_script('./my_script.rb')

        system({'PIPELINE_USER_SCRIPT' => './my_script.rb'}, 'run_user_script > out')
        assert_git_updated_recursive_submodules

        assert_equal "Hello from my_script", File.read('out').strip.split("\n").last
      end
    end
  end

  def write_fake_script(path)
    File.open(path, 'w') do |file|
      file << <<-'EOF'
#!/usr/bin/env ruby

puts 'Hello from my_script'
      EOF
    end

    FileUtils.chmod 0755, path
  end
end
