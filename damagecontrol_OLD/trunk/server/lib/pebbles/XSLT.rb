module DamageControl
  module XSLT
    def xslt(xml, xsl, out, options="")
      cmd = "xsltproc #{options} '#{xsl}' '#{xml}' > '#{out}'"
      system(cmd)
      if($? != 0)
        msg = "Error executing xsltproc\n"
        msg += %{
This could happen for the following reasons:
o the xsl or xml was invalid
o xsltproc is not installed - get it from http://xmlsoft.org/XSLT/downloads.html (libxslt and libxml2)
o xsltproc might not be on the path
o xsltproc might be of a version that is incompatible with DamageControl.}
        raise msg
      end
    end

    module_function :xslt
  end
  
end