require 'rexml/pullparser'

module DamageControl

  class HTMLTemplate
    def generate(build_result)
    %{
<html>
  <head>
    <title>#{build_result.project_name}</title>
  </head>
  <body>
    <div class="main">
      <h3 class="projectname">#{build_result.project_name}</h3>
      Status: #{build_result.error_message}
    </div>
  </body>
</html>
}
    end
  end
end