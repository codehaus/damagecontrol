require 'open-uri'
require 'net/http'
require 'cgi'

# Adds multipart support to Net::HTTP
# based on Code from Patrick May
# http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/113774
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
      "Content-Type: #{@mime_type}\r\n\r\n" + content + "\r\n"
    end
  end

  class HTTP

    def post_multipart(path, params, header={}, dest=nil, boundary="----------ThIs_Is_tHe_bouNdaRY_$") # :yield: self  
      body = params.collect { |p|
        "--" + boundary + "\r\n" + p.to_multipart
      }.join("") + "--" + boundary + "--" + "\r\n"

      header["Content-Type"] = "multipart/form-data; boundary=" + boundary
      header["Content-Length"] = "#{body.length}"

      post(path, body, header, dest)
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
