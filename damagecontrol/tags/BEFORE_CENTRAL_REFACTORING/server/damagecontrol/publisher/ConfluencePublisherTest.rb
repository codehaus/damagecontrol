require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/publisher/ConfluencePublisher'

# Authors: Zohar Melamed, Aslak Hellesoy
#
module DamageControl

  class ConfluencePublisherTest < Test::Unit::TestCase
  
    def test_should_be_able_to_create_new_page    
      content = %{
||jon||what||
|you|think|
      }
      
      cp = ConfluencePublisher.new("docs.codehaus.org", "damagecontrol", "password")
      cp.post("DC", "TestArea","Test2", content)
      
    end
    
  end
end
