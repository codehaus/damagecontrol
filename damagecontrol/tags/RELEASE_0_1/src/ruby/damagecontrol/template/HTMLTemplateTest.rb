require 'test/unit'
require 'damagecontrol/template/HTMLTemplate'

module DamageControl
  class HTMLTemplateTest < Test::Unit::TestCase
    
    def test_failed_build
      build = Build.new("Test Project")
      build.label = "999"
      build.timestamp = "20030929145347"
      build.error_message = "Knockout"
      build.successful = false
      build.build_duration_seconds = 4

      htmlTemplate = HTMLTemplate.new
      assert_equal(expected, htmlTemplate.generate(build))
    end

  private

    def expected
    %{
<html>
  <head>
    <title>Test Project</title>
  </head>
  <body>
    <div class="main">
      <h3 class="projectname">Test Project</h3>
      Build Status: Knockout<br/>
      Build Duration: 4 seconds<br/>
    </div>
  </body>
</html>
}
    end
  end
end
