# :nodoc:
# Version:: $Id: fileoutputter.rb,v 1.1 2004/03/31 19:02:49 tirsen Exp $

require "log4r/outputter/iooutputter"
require "log4r/staticlogger"

module Log4r

  # Convenience wrapper for File. Additional hash arguments are:
  #
  # [<tt>:filename</tt>]   Name of the file to log to.
  # [<tt>:trunc</tt>]      Truncate the file?
  class FileOutputter < IOOutputter
    attr_reader :trunc, :filename

    def initialize(_name, hash={})
      super(_name, nil, hash)
      _filename = (hash[:filename] or hash['filename'])
      @trunc = Log4rTools.decode_bool(hash, :trunc, true)
      raise TypeError, "Filename must be specified" if _filename.nil?
      if _filename.class != String
        raise TypeError, "Argument 'filename' must be a String", caller
      end

      @filename = _filename
      @out = File.new(@filename, (@trunc ? "w" : "a")) 
      Logger.log_internal {
        "FileOutputter '#{@name}' writing to #{@filename}"
      }
    end

  end
end
