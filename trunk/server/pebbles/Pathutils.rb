module Pebbles
  module Pathutils

    def filepath_to_nativepath(path, escaped)
      cygpath = IO.popen("cygpath --windows #{path}").read.chomp
      if(cygpath)
        escaped ? cygpath.gsub(/\\/, "\\\\\\\\") : cygpath
      else
        path
      end
    end

    def filepath_to_nativeurl(path)
      cygpath = IO.popen("cygpath --type mixed #{path}").read.chomp[2..-1]
      if(cygpath)
        "file://#{cygpath}"
      else
        path
      end
    end

  end
end
