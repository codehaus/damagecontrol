module Pebbles
  module Pathutils

    def filepath_to_nativepath(path, escaped)
      result = IO.popen("cygpath --windows #{path}").read.chomp
      escaped ? result.gsub(/\\/, "\\\\\\\\") : result
    end

    def filepath_to_nativeurl(path)
      "file://" + IO.popen("cygpath --type mixed #{path}").read.chomp[2..-1]
    end

  end
end
