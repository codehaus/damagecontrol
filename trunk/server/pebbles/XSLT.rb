module DamageControl
  module XSLT
    include FileUtils

    def xslt(xml, xsl, out)
      result = ""
      cmd = "#{damagecontrol_home}/bin", "xsltproc --output '#{out}' '#{xsl}' '#{xml}'"
      system(cmd)
      if($? != 0)
        result += "Error executing XSLT process"
        result += %{
This could happen for the following reasons:
o the xsl or xml was invalid
o xsltproc is not installed
o xsltproc might not be on the path
o xsltproc might be of a version that is incompatible with DamageControl.}
      end
      result
    end

    module_function :xslt
  end
  
end