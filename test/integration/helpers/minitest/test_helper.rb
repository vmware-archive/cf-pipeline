require 'tmpdir'

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
