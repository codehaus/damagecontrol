module DamageControl

  class HTMLTemplate
    def generate(build)
    %{
<html>
  <head>
    <title>#{build.project_name}</title>
  </head>
  <body>
    <div class="main">
      <h3 class="projectname">#{build.project_name}</h3>
      Status: #{build.error_message}
    </div>
  </body>
</html>
}
    end
    
    def file_type
      "html"
    end
  end
end