require 'open-uri'
require 'net/http'
require 'cgi'

module Net
  class Param
    def initialize(k, v)
      @k = k
      @v = v
    end
   
    def to_multipart
      "Content-Disposition: form-data; name=\"#{CGI::escape(@k)}\"\r\n\r\n#{@v}\r\n"
    end
  end

  class FileParam
    def initialize(k, file, mime_type)
      @k = k
      @file = file
      @mime_type = mime_type
    end

    def to_multipart
      content = File.open(@file).read
      "Content-Disposition: form-data; name=\"#{CGI::escape(@k)}\"; filename=\"#{File.basename(@file)}\"\r\n" +
#      "Content-Transfer-Encoding: binary\r\n" +
      "Content-Type: #{@mime_type}\r\n\r\n" + content + "\r\n"
    end
  end

  class HTTP

    def post_multipart(path, params, header={}, dest=nil, boundary="-----------------------------16558394734534412381714907510") # :yield: self  
      data = params.collect { |p|
        boundary + "\r\n" + p.to_multipart
      }.join("") + boundary + "\r\n\r\n"
      header["Content-Type"] = "multipart/form-data; boundary=" + boundary
      header["Content-Length"] = "#{data.length}"

      post(path, data, header, dest)
    end
    
    alias :old_post :post
    def post(path, data, initheader = nil, dest = nil)
      puts "----POST----"
      puts path
      puts "------------"
      if(initheader)
        initheader.each {|k,v|
          puts "#{k}: #{v}"
        }
      end
      puts
      puts data

      response, data = old_post(path, data, initheader, dest)

      puts "----POST RESP----"
      puts response.class.name
      puts "------------"
      response.each {|k,v|
        puts "#{k}: #{v}"
      }
      
      return response, data
    end

    alias :old_get :get
    def get(path, initheader = nil, dest = nil)
      puts "----GET-----"
      puts path
      puts "------------"
      if(initheader)
        initheader.each {|k,v|
          puts "#{k}: #{v}"
        }
      end
      
      response, data = old_get(path, initheader, dest)

      puts "----GET RESP----"
      puts response.class.name
      puts "------------"
      response.each {|k,v|
        puts "#{k}: #{v}"
      }
      
      return response, data
    end
  end
end
