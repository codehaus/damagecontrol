require 'test/unit'
require 'rexml/document'
require 'pebbles/mockit'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class BuildTest < Test::Unit::TestCase
    include MockIt

    def test_to_rss
      t = Time.utc(2004, 9, 3, 15, 0, 0)
      expected_time_text = t.strftime("%a, %d %b %Y %H:%M:%S %Z")
      build = Build.new("myproject", {}, "http://builds.codehaus.org/public/")
      build.dc_creation_time = t
      build.label = 42
      build.status = Build::SUCCESSFUL
      build.changesets = new_mock
      build.changesets.__expect(:to_rss_description) {
        "Fixed bug 42"
      }
      item = build.to_rss_item
      assert_equal("myproject: Build #42 SUCCESSFUL", item.get_text("title").value)
      assert_equal("http://builds.codehaus.org/public/project/myproject?dc_creation_time=20040903150000", item.get_text("link").value)
      assert_equal(t.to_rfc2822, item.get_text("pubDate").value)
      assert_equal("Fixed bug 42", item.get_text("description").value)
    end
    
  end

end
