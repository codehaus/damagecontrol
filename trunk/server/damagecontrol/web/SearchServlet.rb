require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl
  class SearchServlet < AbstractAdminServlet
    def initialize(build_history_repository)
      super(:public, nil, build_history_repository, nil)
    end
    
    def tasks
      result = super
      unless project_name.nil?
        result += [
          task(:icon => "smallicons/navigate_left.png", :name => "Back to project", :url => "../project/#{project_name}")
        ]
      end 
      result
    end

    def default_action
      search
    end
    
    def search
      search_string = request.query['search']
      regexp = Regexp.new(search_string, Regexp::IGNORECASE)
      
      required_project_name = request.query['project_name']
      builds = build_history_repository.search(regexp, required_project_name)
      find_method = "search"
      
      render("search_results.erb", binding)
    end
    
  end
end
