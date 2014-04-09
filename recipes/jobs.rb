chef_gem 'builder'
include_recipe 'jenkins::server'

def add_jenkins_user_job(name, job_settings)
  job_dir = ::File.join(node['jenkins']['server']['home'], 'jobs', name)
  job_config = ::File.join(job_dir, 'config.xml')

  directory job_dir do
    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['user']
    mode 0755
    action :create
  end

  file job_config do
    content JenkinsClient::Job.from_config(job_settings).to_xml
    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['user']
    mode 0644
    notifies :restart, 'service[jenkins]', :delayed
  end
end

node['cf_pipeline']['jobs'].each do |name, job_settings|
  add_jenkins_user_job(name, job_settings.dup)
end
