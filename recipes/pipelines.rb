chef_gem 'builder'

def add_jenkins_job_for_deploy(name, pipeline_settings)
  job = bare_jenkins_job(pipeline_settings)

  options = %W(
    --non-interactive
    --release-name #{name}
    --release-repo #{pipeline_settings.fetch('git')}
    --release-ref #{pipeline_settings.fetch('release_ref')}
    --infrastructure #{pipeline_settings.fetch('infrastructure')}
    --deployments-repo #{pipeline_settings.fetch('deployments_repo')}
    --deployment-name #{pipeline_settings.fetch('deployment_name')}
    --rebase
  ).join(' ')

  job.command = command_for_sub_command("SHELL=/bin/bash bundle exec cf_deploy #{options}")
  job.downstream_jobs = ["#{name}-system_tests"]

  add_jenkins_job_directly(job, name, 'deploy')
end

def add_jenkins_job_for_system_tests(name, pipeline_settings)
  job = bare_jenkins_job(pipeline_settings)
  job.command = command_for_sub_command('script/run_system_tests')
  job.downstream_jobs = ["#{name}-release_tarball"]

  add_jenkins_job_directly(job, name, 'system_tests')
end

def add_jenkins_job_for_release_tarball(name, pipeline_settings)
  job = bare_jenkins_job(pipeline_settings)
  job.command = command_for_sub_command("rm -rf dev_releases; echo #{name} | bosh create release --with-tarball --force")
  job.artifact_glob = 'dev_releases/*.tgz'

  add_jenkins_job_directly(job, name, 'release_tarball')
end

def add_jenkins_job_directly(job, name, step)
  job_dir = ::File.join(node['jenkins']['server']['home'], 'jobs', "#{name}-#{step}")
  job_config = ::File.join(job_dir, 'config.xml')

  directory job_dir do
    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['user']
    mode 00755
    action :create
  end

  file job_config do
    content job.to_xml

    owner node['jenkins']['server']['user']
    group node['jenkins']['server']['user']
    mode 00644
  end

  jenkins_job "#{name}-#{step}" do
    config job_config
    action :update
  end
end

def bare_jenkins_job(pipeline_settings)
  job = JenkinsClient::Job.new
  job.git_repo_url = pipeline_settings.fetch('git')
  job.git_repo_branch = pipeline_settings.fetch('release_ref')
  job
end

def command_for_sub_command(sub_command)
  <<-COMMAND
#!/bin/bash
set -x

source /usr/local/share/chruby/chruby.sh
chruby 1.9.3
gem install bundler --no-ri --no-rdoc --conservative
bundle install

source /usr/local/share/gvm/scripts/gvm
gvm use go1.2

#{sub_command}
  COMMAND
end

node['cf_pipeline']['pipelines'].each do |name, pipeline_settings|
  add_jenkins_job_for_deploy(name, pipeline_settings)
  add_jenkins_job_for_system_tests(name, pipeline_settings)
  add_jenkins_job_for_release_tarball(name, pipeline_settings)
end
