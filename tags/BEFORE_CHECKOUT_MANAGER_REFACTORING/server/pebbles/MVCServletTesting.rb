module Pebbles
  module MVCServletTesting

    class FakeHttpMessage

      def initialize()
        @headers = Hash.new()
      end

      def [](field)
        @headers[field.downcase]
      end

      def []=(field, value)
        @headers[field.downcase] = value
      end
      
      def method_missing(*args)
        ""
      end

    end

    class FakeHttpRequest < FakeHttpMessage
      attr_accessor :query
      
    end
    
    class FakeHttpResponse < FakeHttpMessage
      attr_accessor :body
      attr_accessor :status
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
