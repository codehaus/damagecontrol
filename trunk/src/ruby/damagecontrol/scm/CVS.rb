require 'damagecontrol/scm/SCM'
require 'damagecontrol/FileSystem'

module DamageControl

  # format of path is cvsroot:module
  # examples
  # :local:/cvsroot/damagecontrol:damagecontrol
  # :pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol
  # if pserver is used, the user is assumed to already be authenticated with cvs login
  # prior to starting damagecontrol
  class CVS < SCM
    def initialize(filesystem = FileSystem.new)
      @filesystem = filesystem
    end
  
    def handles_path?(path)
      parse_path(path)
    end
    
    def checkout(path, directory, &proc)
      directory = File.expand_path(directory)
      
      puts "Checking out to " + directory
      
      cvsroot, modoole = parse_path(path)[1,2]
      @filesystem.makedirs(directory)
      @filesystem.chdir(directory)

      if(checked_out?(directory, modoole))
        cvs(update_command(cvsroot), &proc)
      else
        cvs(checkout_command(cvsroot, modoole, directory), &proc)
      end
    end

  private

    def checked_out?(directory, modoole)
      rootcvs = File.expand_path("#{directory}/#{modoole}/CVS/Root")
      File.exists?(rootcvs)
    end
  
    def checkout_command(cvsroot, modoole, directory)
      "-d #{cvsroot} co #{modoole}"
    end

    def update_command(cvsroot)
      "-d #{cvsroot} update -d -P"
    end

    def parse_path(path)
      /^(:.*:.*):(.*)$/.match(path)
    end
    
    def cvs(cmd)
      cmd = "cvs #{cmd}"
      puts cmd
      io = IO.popen(cmd) do |io|
        io.each_line do |progress|
          yield progress
        end
      end
    end
    
  end   
end