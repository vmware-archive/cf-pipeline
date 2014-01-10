dest_dir = "#{Chef::Config[:file_cache_path]}/cf_deployer"
git dest_dir do
  repository 'https://github.com/pivotal-cf-experimental/cf-deployer.git'
  revision node['cf_pipeline']['cf_deployer_ref']
end

bash 'remove old gem files' do
  command 'rm -f *.gem'
  cwd dest_dir
end

bash 'build cf_deployer gem' do
  command 'source `which go_and_ruby` && gem build cf_deployer.gemspec'
  cwd dest_dir
end

bash 'install cf_deployer gem' do
  command 'source `which go_and_ruby` && gem install --local cf_deployer-*.gem'
  cwd dest_dir
end
