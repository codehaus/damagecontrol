module Pebbles
  module Pathutils

    system("cygpath C:\\\\")
    CYGWIN = $? == 0

    def filepath_to_nativepath(path, escaped)
      if(CYGWIN)
        cygpath = IO.popen("cygpath --windows #{path}").read.chomp
        escaped ? cygpath.gsub(/\\/, "\\\\\\\\") : cygpath
      else
        path
      end
    end

    def filepath_to_nativeurl(path)
      if(CYGWIN)
        urlpath = filepath_to_nativepath(path, false).gsub(/\\/, "/")
        path = "/#{urlpath}"
      end
      "file://#{path}"
    end

    def nativepath_to_filepath(path)
      if(CYGWIN)
        cygpath = IO.popen("cygpath '#{path}'").read.chomp
      else
        path
      end
    end

  end
end
