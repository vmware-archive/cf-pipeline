require 'minitest/autorun'
require 'tmpdir'

describe "pipeline_deploy script" do
  it "calls cf_deploy with the right options, using the right environment variables" do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        FileUtils.mkdir 'stub_binaries'
        write_option_echoing_script 'stub_binaries/cf_deploy'

        env = {
          'PATH' => "#{File.join(Dir.pwd, 'stub_binaries')}:#{ENV['PATH']}",
          'RELEASE_NAME' => 'my_release_name',
          'RELEASE_REPO' => 'my_release_repo',
          'RELEASE_REF' => 'my_release_ref',
          'INFRASTRUCTURE' => 'my_infrastructure',
          'DEPLOYMENTS_REPO' => 'my_deployments_repo',
          'DEPLOYMENT_NAME' => 'my_deployment_name',
        }

        FileUtils.touch 'Gemfile'

        system(env, 'pipeline_deploy > out')

        assert_match "my_release_name my_release_repo my_release_ref my_infrastructure my_deployments_repo my_deployment_name true true", File.read('out')
      end
    end
  end

  def write_option_echoing_script(path)
    File.open(path, 'w') do |file|
      file << <<-'EOF'
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

    FileUtils.chmod 0755, path
  end
end
