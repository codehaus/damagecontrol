module Pebbles
  module MVCServletTesting
    class FakeHttpRequest
      attr_accessor :query
      
      def method_missing(*args)
        ""
      end
    end
    
    class FakeHttpResponse
      attr_accessor :body
      
      def method_missing(*args)
        ""
      end
    end
    
    def do_request(query)
      response = FakeHttpResponse.new
      request = FakeHttpRequest.new
      request.query = query
      begin
        Thread.current["request"] = request
        Thread.current["response"] = response
        yield
      ensure
        Thread.current["request"] = nil
        Thread.current["response"] = nil
      end
      response.body
    end
  end
end