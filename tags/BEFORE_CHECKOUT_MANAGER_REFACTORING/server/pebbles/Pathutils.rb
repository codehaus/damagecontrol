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
        path = IO.popen("cygpath --type mixed #{path}").read.chomp[2..-1]
      end
      "file://#{path}"
    end

  end
end
