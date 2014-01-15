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
