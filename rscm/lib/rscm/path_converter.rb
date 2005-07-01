WIN32 = RUBY_PLATFORM == "i386-mswin32"
CYGWIN = RUBY_PLATFORM == "i386-cygwin"
WINDOWS = WIN32 || CYGWIN
if(WINDOWS)
  HOMEDIR = RSCM::PathConverter.nativepath_to_filepath("#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}").gsub(/\\/, "/")
else
  HOMEDIR = ENV['HOME']
end

require 'fileutils'
require 'rscm/logging'

def with_working_dir(dir)
  # Can't use Dir.chdir{ block } - will fail with multithreaded code.
  # http://www.ruby-doc.org/core/classes/Dir.html#M000790
  #
  prev = Dir.pwd
  begin
    dir = File.expand_path(dir)
    FileUtils.mkdir_p(dir)
    Dir.chdir(dir)
    yield
  ensure
    Dir.chdir(prev)
  end
end

# Utility for converting between win32 and cygwin paths. Does nothing on *nix.
module RSCM
  module PathConverter
    def filepath_to_nativepath(path, escaped)
      return nil if path.nil?
      path = File.expand_path(path)
      if(WIN32)
        path.gsub(/\//, "\\")
      elsif(CYGWIN)
        cmd = "cygpath --windows #{path}"
        Better.popen(cmd) do |io|
          cygpath = io.read.chomp
          escaped ? cygpath.gsub(/\\/, "\\\\\\\\") : cygpath
        end
      else
        path
      end
    end

    def filepath_to_nativeurl(path)
      return nil if path.nil?
      if(WINDOWS)
        urlpath = filepath_to_nativepath(path, false).gsub(/\\/, "/")
        "file:///#{urlpath}"
      else
        "file://#{File.expand_path(path)}"
      end
    end

    def nativepath_to_filepath(path)
      return nil if path.nil?
      if(WIN32)
        path.gsub(/\//, "\\")
      elsif(CYGWIN)
        path = path.gsub(/\\/, "/")
        cmd = "cygpath --unix #{path}"
        Better.popen(cmd) do |io|
          io.read.chomp
        end
      else
        path
      end
    end
    
    def ensure_trailing_slash(url)
      return nil if url.nil?
      if(url && url[-1..-1] != "/")
        "#{url}/"
      else
        url
      end
    end

    module_function :filepath_to_nativepath
    module_function :filepath_to_nativeurl
    module_function :nativepath_to_filepath
    module_function :ensure_trailing_slash
  end
end
