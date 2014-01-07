template "#{node['jenkins']['server']['home']}/config.xml" do
  source 'jenkins_config.xml.erb'
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['user']
  mode 00644

  github_config = node['cf_pipeline']['github_oauth']

  variables(
    'use_security' => github_config.fetch('use_security', true),
    'github_user_org' => github_config['organization'],
    'github_user_admins' => github_config['admins'],
    'github_client_id' => github_config['client_id'],
    'github_client_secret' => github_config['client_secret']
  )
end
