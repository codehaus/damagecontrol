module Pebbles
  module Pathutils

    def filepath_to_nativepath(path, escaped)
      return path
      cygpath = IO.popen("cygpath --windows #{path}").read.chomp
      if(cygpath)
        escaped ? cygpath.gsub(/\\/, "\\\\\\\\") : cygpath
      else
        path
      end
    end

    def filepath_to_nativeurl(path)
      return "file://#{path}"
      cygpath = IO.popen("cygpath --type mixed #{path}").read.chomp[2..-1]
      if(cygpath)
        "file://#{cygpath}"
      else
        "file://#{path}"
      end
    end

  end
end
