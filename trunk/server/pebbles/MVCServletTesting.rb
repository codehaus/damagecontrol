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
      def initialize(path_info)
        @path_info = path_info
      end
      attr_accessor :query
      attr_accessor :path_info
    end
    
    class FakeHttpResponse < FakeHttpMessage
      attr_accessor :body
      attr_accessor :status
    end
    
    def do_request(path_info, query)
      response = FakeHttpResponse.new
      request = FakeHttpRequest.new(path_info)
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
