require 'ftools'

module DamageControl
  # This class contains common file system
  # operations. Keeping them in a single
  # class makes it easy to mock out file
  # system operations during unit tests
  class FileSystem
    def makedirs(dir)
      File.makedirs(dir)
    end

    def chdir(dir)
      Dir.chdir(dir)
    end

    def newFile(*args)
      File.new(*args)
    end
    
    def foreach(dir)
      Dir.foreach(dir) { |file|
        yield file
      }
    end
  end
end
