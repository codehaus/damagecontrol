require 'cgi'
require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl
  class RssServlet < AbstractAdminServlet
    def initialize(build_history_repository, project_root_url)
      super(:public, nil, build_history_repository, nil)
      @project_root_url = project_root_url      
    end

    def cacheable?
      true
    end

    def rss
      if request["If-None-Match"] == current_etag
        response.status = WEBrick::HTTPStatus::NotModified.code
        response.body = ""
      else
        response.body = build_history_repository.to_rss(project_name, @project_root_url + CGI.escape(project_name)).to_s
        response["ETag"] = current_etag
      end
    end

    def default_action
      rss
    end

    def content_type
      "application/rss+xml"
    end

    def current_etag
      build = build_history_repository.last_completed_build(project_name)
      'W/"' + build.dc_creation_time.ymdHMS.gsub('"', '\\"') + '"'
    end
    
  end
end
