require 'minitest/autorun'
require 'tmpdir'

describe "pipeline_deploy script" do
  it "bundles, then calls cf_deploy with the right options, using the right environment variables" do
    in_tmp_dir do
      make_gemfile_for_fake_cf_deployer

      env = {
        'RELEASE_NAME' => 'my_release_name',
        'RELEASE_REPO' => 'my_release_repo',
        'RELEASE_REF' => 'my_release_ref',
        'INFRASTRUCTURE' => 'my_infrastructure',
        'DEPLOYMENTS_REPO' => 'my_deployments_repo',
        'DEPLOYMENT_NAME' => 'my_deployment_name',
      }

      system(env, 'pipeline_deploy > out')

      assert_match "my_release_name my_release_repo my_release_ref my_infrastructure my_deployments_repo my_deployment_name true true", File.read('out')
    end
  end

  def make_gemfile_for_fake_cf_deployer
    write 'Gemfile', gemfile_with_cf_deployer

    FileUtils.mkdir_p 'cf-deployer/bin'
    write 'cf-deployer/cf-deployer.gemspec', fake_cf_deployer_gemspec
    write 'cf-deployer/bin/cf_deploy', option_echoing_script, 0755
  end

  def fake_cf_deployer_gemspec
    <<-GEMSPEC
Gem::Specification.new do |s|
  s.name        = "cf_deployer"
  s.authors     = %w{An Imposter}
  s.summary     = "a fake gem"
  s.version     = "0.3.0"
  s.executables = %w{cf_deploy}
end
    GEMSPEC
  end

  def in_tmp_dir(&block)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        block.call
      end
    end
  end

  def write(path, script, mode=0444)
    File.open(path, 'w') do |file|
      file << script
    end

    FileUtils.chmod mode, path
  end

  def gemfile_with_cf_deployer
    <<-GEMFILE
source 'https://rubygems.org'
gem "cf_deployer", path: "cf-deployer"
    GEMFILE
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
