require 'cgi'
require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl
  class RssServlet < AbstractAdminServlet
    def initialize(build_history_repository, url)
      super(:public, nil, build_history_repository, nil)
      @url = url
    end

    def cacheable?
      true
    end

    def rss
      if request["If-None-Match"] == current_etag(request.path_info)
        response.status = WEBrick::HTTPStatus::NotModified.code
        response.body = ""
      else
        response.body = build_history_repository.to_rss(request.path_info, @url + "/" + CGI.escape(request.path_info)).to_s
        response["ETag"] = current_etag(request.path_info)
      end
    end

    def default_action
      rss
    end

    def content_type
      "application/rss+xml"
    end

    def current_etag(project_name)
      build = build_history_repository.last_completed_build(project_name)
      'W/"' + build.dc_creation_time.ymdHMS.gsub('"', '\\"') + '"'
    end
    
  end
end
