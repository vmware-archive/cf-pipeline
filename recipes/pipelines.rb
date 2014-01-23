chef_gem 'builder'
include_recipe 'jenkins::server'

def add_jenkins_job_for_deploy(name, env, pipeline_settings)
  job = bare_jenkins_job(pipeline_settings)

  job.command = "pipeline_deploy"
  job.downstream_jobs = ["#{name}-system_tests"]

  add_jenkins_job_directly(job, name, 'deploy', pipeline_settings, env)
end

def add_jenkins_job_for_system_tests(name, env, pipeline_settings)
  job = bare_jenkins_job(pipeline_settings)
  job.command = 'test_deployment'
  job.downstream_jobs = ["#{name}-release_tarball"]

  add_jenkins_job_directly(job, name, 'system_tests', pipeline_settings, env)
end

def add_jenkins_job_for_release_tarball(name, env, pipeline_settings)
  job = bare_jenkins_job(pipeline_settings)
  job.command = "create_release_tarball"
  job.artifact_glob = 'dev_releases/*.tgz'

  add_jenkins_job_directly(job, name, 'release_tarball', pipeline_settings, env)
end

def add_jenkins_job_directly(job, name, step, pipeline_settings, extra_env)
  job_dir = ::File.join(node['jenkins']['server']['home'], 'jobs', "#{name}-#{step}")
  job_config = ::File.join(job_dir, 'config.xml')

  directory job_dir do
    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['user']
    mode 00755
    action :create
  end

  job.env = {
    'PIPELINE_RELEASE_NAME' => pipeline_settings.fetch('release_name', name),
    'PIPELINE_RELEASE_REPO' => pipeline_settings.fetch('git'),
    'PIPELINE_RELEASE_REF' => pipeline_settings.fetch('release_ref'),
    'PIPELINE_INFRASTRUCTURE' => pipeline_settings.fetch('infrastructure'),
    'PIPELINE_DEPLOYMENTS_REPO' => pipeline_settings.fetch('deployments_repo'),
    'PIPELINE_DEPLOYMENT_NAME' => pipeline_settings.fetch('deployment_name'),
  }.merge(extra_env)

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

env = node['cf_pipeline']['env']
env_overrides = node['cf_pipeline'].fetch('env_overrides', {})

node['cf_pipeline']['pipelines'].each do |name, pipeline_settings|
  merged_env = env.merge(env_overrides.fetch(name, {}))
  add_jenkins_job_for_deploy(name, merged_env, pipeline_settings)
  add_jenkins_job_for_system_tests(name, merged_env, pipeline_settings)
  add_jenkins_job_for_release_tarball(name, merged_env, pipeline_settings)
end
