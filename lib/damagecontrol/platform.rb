require 'rbconfig'

module DamageControl
  module Platform
    def family
      target_os = Config::CONFIG["target_os"] or ""
      return "darwin" if target_os.downcase =~ /darwin/
      return "win32"  if target_os.downcase =~ /32/
      return "cygwin" if target_os.downcase =~ /cyg/
      return "linux"
    end
  end
end
