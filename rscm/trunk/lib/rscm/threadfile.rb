# Patch Ruby so current dir is unique to each thread.

class Module
  def alias_class_method( new, old )
    instance_eval "alias #{new.id2name} #{old.id2name}"
  end
end

# Patch thread so it initially has a local var :pwd pointing
# to the *original* current dir
class Thread
  @@initial_wd = Dir.pwd
  alias :old_initialize :initialize
  
  def initialize(*args, &proc)
    self[:pwd] = @@initial_wd
    old_initialize(*args) do |*args|
      proc.call(args)
    end
  end
end

# Patch Dir so that chdir and pwd uses a thread-local
# var for current dir
class Dir
  alias_class_method :old_chdir, :chdir
  def Dir.chdir(dir) # TODO: handle with block
    Dir.old_chdir(File.expand_path(dir))
    Thread.current[:pwd] = File.old_expand_path(dir)
  end

  alias_class_method :old_pwd, :pwd
  def Dir.pwd
    Thread.current[:pwd] || Dir.old_pwd
  end

  alias_class_method :old_entries, :entries
  def Dir.entries(dir)
    dir = File.old_expand_path(dir)
    Dir.old_entries(dir)
  end
end

# Patch File so it uses Dir.pwd to expand a path
class File
  alias_class_method :old_expand_path, :expand_path

  def File.expand_path(p)
    p = p.gsub(/\\/, '/')
    old_expanded = File.old_expand_path(p)
    if(p == old_expanded)
      p
    else
      File.old_expand_path(Dir.pwd + "/" + p)
    end
  end
  
end