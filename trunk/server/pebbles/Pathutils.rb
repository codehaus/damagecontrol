module Pebbles
  module Pathutils

    def filepath_to_nativepath(path, escaped)
      if(cygwin?)
        cygpath = IO.popen("cygpath --windows #{path}").read.chomp
        escaped ? cygpath.gsub(/\\/, "\\\\\\\\") : cygpath
      else
        path
      end
    end

    def filepath_to_nativeurl(path)
      if(cygwin?)
        cygpath = IO.popen("cygpath --type mixed #{path}").read.chomp[2..-1]
        "file://#{cygpath}"
      else
        "file://#{path}"
      end
    end

    def cygwin?
      system("cygpath C:\\\\")
      $? == 0
    end

  end
end
