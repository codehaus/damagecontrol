module Pebbles
  module Pathutils
    WIN32 = RUBY_PLATFORM == "i386-mswin32"
    CYGWIN = RUBY_PLATFORM == "i386-cygwin"

    def filepath_to_nativepath(path, escaped)
      path = File.expand_path(path)
      if(WIN32)
        path.gsub(/\//, "\\")
      elsif(CYGWIN)
        cygpath = IO.popen("cygpath --windows #{path}").read.chomp
        escaped ? cygpath.gsub(/\\/, "\\\\\\\\") : cygpath
      else
        path
      end
    end

    def filepath_to_nativeurl(path)
      if(CYGWIN || WIN32)
        urlpath = filepath_to_nativepath(path, false).gsub(/\\/, "/")
        path = "/#{urlpath}"
      end
      "file://#{path}"
    end

    def nativepath_to_filepath(path)
      if(WIN32)
        path.gsub(/\//, "\\")
      elsif(CYGWIN)
        cygpath = IO.popen("cygpath '#{path}'").read.chomp
      else
        path
      end
    end

  end
end
