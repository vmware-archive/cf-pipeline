chef_gem 'builder'
include_recipe 'jenkins::server'

def add_jenkins_job_for_deploy(name, pipeline_settings)
  job = bare_jenkins_job(pipeline_settings)

  job.command = "pipeline_deploy"
  job.downstream_jobs = ["#{name}-system_tests"]

  add_jenkins_job_directly(job, name, 'deploy', pipeline_settings)
end

def add_jenkins_job_for_system_tests(name, pipeline_settings)
  job = bare_jenkins_job(pipeline_settings)
  job.command = 'test_deployment'
  job.downstream_jobs = ["#{name}-release_tarball"]

  add_jenkins_job_directly(job, name, 'system_tests', pipeline_settings)
end

def add_jenkins_job_for_release_tarball(name, pipeline_settings)
  job = bare_jenkins_job(pipeline_settings)
  job.command = "create_release_tarball"
  job.artifact_glob = 'dev_releases/*.tgz'

  add_jenkins_job_directly(job, name, 'release_tarball', pipeline_settings)
end

def add_jenkins_job_directly(job, name, step, pipeline_settings)
  job_dir = ::File.join(node['jenkins']['server']['home'], 'jobs', "#{name}-#{step}")
  job_config = ::File.join(job_dir, 'config.xml')

  directory job_dir do
    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['user']
    mode 00755
    action :create
  end

  job.env = {
    'RELEASE_NAME' => name,
    'RELEASE_REPO' => pipeline_settings.fetch('git'),
    'RELEASE_REF' => pipeline_settings.fetch('release_ref'),
    'INFRASTRUCTURE' => pipeline_settings.fetch('infrastructure'),
    'DEPLOYMENTS_REPO' => pipeline_settings.fetch('deployments_repo'),
    'DEPLOYMENT_NAME' => pipeline_settings.fetch('deployment_name'),
  }

  file job_config do
    content job.to_xml

    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['user']
    mode 00644

    notifies :restart, 'service[jenkins]', :delayed
  end
end

def bare_jenkins_job(pipeline_settings)
  job = JenkinsClient::Job.new
  job.git_repo_url = pipeline_settings.fetch('git')
  job.git_repo_branch = pipeline_settings.fetch('release_ref')
  job
end

node['cf_pipeline']['pipelines'].each do |name, pipeline_settings|
  add_jenkins_job_for_deploy(name, pipeline_settings)
  add_jenkins_job_for_system_tests(name, pipeline_settings)
  add_jenkins_job_for_release_tarball(name, pipeline_settings)
end
