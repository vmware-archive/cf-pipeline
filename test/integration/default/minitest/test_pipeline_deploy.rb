require 'minitest/autorun'
require_relative 'test_helper'

describe "pipeline_deploy script" do
  it "calls cf_deploy with the right options, using the right environment variables" do
    without_file('/opt/rubies/ruby-1.9.3-p484/bin/cf_deploy') do
      in_tmp_dir do
        make_fake_cf_deployer

        env = {
          'PATH' => "#{File.join(Dir.pwd, 'bin')}:#{ENV['PATH']}",
          'PIPELINE_RELEASE_NAME' => 'my_release_name',
          'PIPELINE_RELEASE_REPO' => 'my_release_repo',
          'PIPELINE_RELEASE_REF' => 'my_release_ref',
          'PIPELINE_INFRASTRUCTURE' => 'my_infrastructure',
          'PIPELINE_DEPLOYMENTS_REPO' => 'my_deployments_repo',
          'PIPELINE_DEPLOYMENT_NAME' => 'my_deployment_name',
        }

        system(env, 'pipeline_deploy > out')

        assert_match "my_release_name my_release_repo my_release_ref my_infrastructure my_deployments_repo my_deployment_name true true", File.read('out')
      end
    end
  end

  def make_fake_cf_deployer
    FileUtils.mkdir_p 'bin'
    write 'bin/cf_deploy', option_echoing_script, 0755
  end

  def write(path, script, mode=0444)
    File.open(path, 'w') do |file|
      file << script
    end

    FileUtils.chmod mode, path
  end

  def option_echoing_script
    <<-'EOF'
#!/usr/bin/env ruby

require 'optparse'

o = {
  non_interactive: false,
  rebase: false,
}
with_args = %w(release_name release_repo release_ref infrastructure deployments_repo deployment_name)
no_args = %w(non_interactive rebase)
OptionParser.new do |opts|
  with_args.each do |opt|
    opts.on("--#{opt.gsub('_', '-')} x") do |x|
      o[opt.to_sym] = x
    end
  end

  no_args.each do |opt|
    opts.on("--#{opt.gsub('_', '-')}") do |x|
      o[opt.to_sym] = x
    end
  end
end.parse!

puts((with_args + no_args).map {|opt_name| o[opt_name.to_sym]}.join(' '))
    EOF
  end
end
