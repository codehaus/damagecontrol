require 'test/unit'
require 'pebbles/RiteMesh'

module Pebbles

  class RiteMeshTest < Test::Unit::TestCase
    include RiteMesh
    
    PAGE = %{
      <html><head><title>my title</title></head>
      <body>
        this is my body
        this is my body
        this is my body
      </body>
      </html>
    }

    def test_can_mesh_title
      assert_equal("decorator stuff my title decorator stuff", mesh(PAGE, "decorator stuff <%= title %> decorator stuff"))
    end
    
    def test_can_mesh_body_and_title
      decorator = %{
      title: <%= title %>
      body:
      content
      <%= body %>
      content
      }
      
      meshed = mesh(PAGE, decorator)
      result = %{
      title: my title
      body:
      content
      
        this is my body
        this is my body
        this is my body
      
      content
      }
      assert_equal(result, meshed)
    end
    
    def test_body_attributes_are_preserved
      assert_equal('<body onLoad="false">blabodybla', mesh('<body onLoad="false">body</body>', '<body>bla<%=body%>bla'))
    end
    
    def test_can_mesh_body_without_html_tags
      page = "<body>aaa</body>"
      assert_equal("aaa", mesh(page, "<%= body %>"))
    end
    
    def test_can_mesh_body_with_unterminated_curly_brace
      page = "<body>}</body>"
      assert_equal("}", mesh(page, "<%= body %>"))
    end
    
    def test_can_mesh_body_with_unterminated_single_quote
      page = "<body>'</body>"
      assert_equal("'", mesh(page, "<%= body %>"))
    end
    
  end
  
end