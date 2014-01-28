cookbook_file "go and ruby script" do
  path '/usr/local/bin/go_and_ruby'
  mode 0755
  source 'go_and_ruby'
end

cookbook_file "deploy script" do
  path '/usr/local/bin/pipeline_deploy'
  mode 0755
  source 'pipeline_deploy'
end

cookbook_file "system tests script" do
  path '/usr/local/bin/test_deployment'
  mode 0755
  source 'test_deployment'
end

cookbook_file "release tarball script" do
  path '/usr/local/bin/create_release_tarball'
  mode 0755
  source 'create_release_tarball'
end

cookbook_file "run user script" do
  path '/usr/local/bin/run_user_script'
  mode 0755
  source 'run_user_script'
end

include_recipe 'cf_pipeline::cf_deployer'
