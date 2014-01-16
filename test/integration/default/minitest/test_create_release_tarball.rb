require 'minitest/autorun'
require_relative 'test_helper'

describe "create_release_tarball script" do
  it "uses bosh to create a release tarball" do
    without_file('/opt/rubies/ruby-1.9.3-p484/bin/bosh') do
      in_tmp_dir do
        FileUtils.mkdir 'dev_releases'
        FileUtils.touch 'dev_releases/some_old_tarball'

        fake_bosh_dir = File.join(Dir.pwd, 'fake_bosh_dir')
        FileUtils.mkdir_p(fake_bosh_dir)
        stub_bosh(File.join(fake_bosh_dir, 'bosh'))

        env = {
          'PATH' => "#{fake_bosh_dir}:#{ENV['PATH']}",
          'PIPELINE_RELEASE_NAME' => 'name_of_the_release'
        }

        system(env, 'create_release_tarball > out')
        output = File.read('out').strip

        assert_match "the dev_releases directory was gone", output
        assert_match "I received 'name_of_the_release' from STDIN", output
        assert_match "I received these arguments: create release --with-tarball --force", output
      end
    end
  end

  def stub_bosh(path)
    File.open(path, 'w') do |file|
      file << <<-'EOF'
#!/usr/bin/env ruby

puts "the dev_releases directory was gone" unless Dir.exists?('dev_releases')

stdin = STDIN.read.chomp
puts "I received '#{stdin}' from STDIN"

puts "I received these arguments: #{ARGV.join(' ')}"
      EOF
    end

    FileUtils.chmod 0755, path
  end
end

