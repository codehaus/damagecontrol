require 'rbconfig'

module DamageControl
  module Platform
    def family
      target_os = Config::CONFIG["target_os"] or ""
      return "popwerpc-darwin" if target_os.downcase =~ /darwin/
      return "win32"  if target_os.downcase =~ /32/
      return "cygwin" if target_os.downcase =~ /cyg/
      # TODO: distinguish between ELF and, err, what's the other one?
      return "linux"
    end
    module_function :family
  end
end

# Add binaries to path
ENV['PATH'] = File.expand_path(File.dirname(__FILE__) + "/../../bin/#{DamageControl::Platform.family}") + File::PATH_SEPARATOR + ENV['PATH']

# Make sure forl works
if(DamageControl::Platform.family == "win32")
  require 'win32/process'
end