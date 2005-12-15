require 'rbconfig'

# TODO: move to RSCM
module DamageControl
  module Platform
    def family
      target_os = Config::CONFIG["target_os"] or ""
      return "powerpc-darwin" if target_os.downcase =~ /darwin/
      return "mswin32"  if target_os.downcase =~ /32/
      return "cygwin" if target_os.downcase =~ /cyg/
      # TODO: distinguish between different binary formats like ELF and a.out (or whatever it's called)
      return "linux"
    end
    module_function :family
    
    def user
      family == "mswin32" ? ENV['USERNAME'] : ENV['USER']
    end
    module_function :user
    
    def prompt(dir=Dir.pwd)
      prompt = "#{dir.gsub(/\//, File::SEPARATOR)} #{user}$"
    end
    module_function :prompt
  end
end

# Add binaries to path
ENV['PATH'] = File.expand_path(File.dirname(__FILE__) + "/../../bin/#{DamageControl::Platform.family}") + File::PATH_SEPARATOR + ENV['PATH']
