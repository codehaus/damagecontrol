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
      Build Status: #{build.status}<br/>
      Build Duration: #{build.duration_seconds} seconds<br/>
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