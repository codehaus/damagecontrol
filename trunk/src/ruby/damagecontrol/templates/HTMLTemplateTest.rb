require 'test/unit'
require 'damagecontrol/templates/HTMLTemplate'

module DamageControl
  class HTMLTemplateTest < Test::Unit::TestCase
    
    def test_failed_build
      build_result = BuildResult.new
      build_result.project_name = "Test Project"
      build_result.label = "999"
      build_result.timestamp = "20030929145347"
      build_result.error_message = "Knockout"
      build_result.successful = false

      htmlTemplate = HTMLTemplate.new
      assert_equal(expected, htmlTemplate.generate(build_result))
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
      Status: Knockout
    </div>
  </body>
</html>
}
    end
  end
end