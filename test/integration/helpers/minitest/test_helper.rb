require 'tmpdir'
require 'json'
require 'rexml/document'
require 'rexml/xpath'

def in_tmp_dir(&block)
  Dir.mktmpdir do |dir|
    Dir.chdir dir do
      block.call
    end
  end
end

def without_file(orig_path, &block)
  backup_path = "#{orig_path}.bak"
  begin
    FileUtils.mv(orig_path, backup_path) if File.exists?(orig_path)
    block.call
  ensure
    FileUtils.mv(backup_path, orig_path) if File.exists?(backup_path)
  end
end

def make_git_repo(path)
  Dir.mkdir(path)
  Dir.chdir(path) do
    `git init .`
    `printf #{path} > who`
    `git add who`
    `git commit -m"who"`
  end
end

def add_submodule(repo, submodule)
  Dir.chdir(repo) do
    `git submodule add ../#{submodule}`
    `git commit -m"submodule #{submodule}"`
  end
end

def git_clone(remote, local)
  Dir.mkdir(local)
  Dir.chdir(local) do
    `git clone ../#{remote} .`
  end
end

def create_git_project_with_submodules(path)
  make_git_repo('grandchild1')
  make_git_repo('grandchild2')
  make_git_repo('child1')
  make_git_repo('child2')
  add_submodule('child1', 'grandchild1')
  add_submodule('child2', 'grandchild2')
  make_git_repo('parent')
  add_submodule('parent', 'child1')
  add_submodule('parent', 'child2')

  git_clone('parent', path)
end

def assert_git_updated_recursive_submodules
  assert_equal 'grandchild1', File.read('child1/grandchild1/who')
  assert_equal 'grandchild2', File.read('child2/grandchild2/who')
end

module JenkinsHelper
  class << self
    def all_jobs
      json = curl "#{host}/api/json"
      JSON.parse(json).fetch('jobs')
    end

    def find_job(job_name)
      all_jobs.detect { |job| job.fetch('name') == job_name }
    end

    def config_for(job_name)
      doc = REXML::Document.new(curl("#{host}/job/#{job_name}/config.xml"))
      JobConfig.new(
        REXML::XPath.first(doc, '//builders/hudson.tasks.Shell/command').text
      )
    end

    def downstream_jobs_for(job_name)
      json = curl "#{host}/job/#{job_name}/api/json"
      JSON.parse(json).fetch('downstreamProjects').map do |project|
        project.fetch('name')
      end
    end

    class JobConfig < Struct.new(:shell_command)
    end

    def curl(command)
      `curl --silent #{command}`
    end

    def host
      "http://127.0.0.1:8080"
    end
  end
end
