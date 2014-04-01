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

  job = JenkinsClient::Job.new
  job.git_repo_url = job_settings.fetch('git')
  job.git_repo_branch = job_settings.fetch('git_ref')
  job.env = ({'PIPELINE_USER_SCRIPT' => job_settings.fetch('script_path')}).merge(job_settings.fetch('env', {}))
  job.downstream_jobs = job_settings.fetch('trigger_on_success', [])
  job.command = 'run_user_script'
  job.artifact_glob = job_settings.fetch('artifact_glob', nil)

  file job_config do
    content job.to_xml
    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['user']
    mode 0644
    notifies :restart, 'service[jenkins]', :delayed
  end
end

node['cf_pipeline']['jobs'].each do |name, job_settings|
  add_jenkins_user_job(name, job_settings)
end
