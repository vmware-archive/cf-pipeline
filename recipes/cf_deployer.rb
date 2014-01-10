dest_dir = "#{Chef::Config[:file_cache_path]}/cf_deployer"
git dest_dir do
  repository 'https://github.com/pivotal-cf-experimental/cf-deployer.git'
  revision node['cf_pipeline']['cf_deployer_ref']
end

bash 'remove old gem files' do
  code 'rm -f *.gem'
  cwd dest_dir
end

bash 'build cf_deployer gem' do
  code 'source `which go_and_ruby` && gem build cf_deployer.gemspec'
  cwd dest_dir
end

bash 'install cf_deployer gem' do
  code 'source `which go_and_ruby` && gem install --both dogapi bosh_cli cf cf_deployer-*.gem'
  cwd dest_dir
end
