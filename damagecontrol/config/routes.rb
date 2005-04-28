ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # default route
  #map.connect '', :controller => 'project', :action => 'index'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'

  # map.connect ':controller/service.wsdl', :action => 'wsdl'
  
  map.connect '', :controller => 'project'

  # Project dependencies
  map.connect 'projects/:id/add_dependency/:to', :controller => 'dependency', :action => "add_dependency"
  map.connect 'projects/:id/remove_dependency/:to', :controller => 'dependency', :action => "remove_dependency"

  map.connect 'projects/:id', :controller => 'project', :action => "view"
  map.connect 'projects/:id/revisions.rss', :controller => "project", :action => "revisions_rss"
  map.connect 'projects/:id/revisions/:revision', :controller => "project", :action => "revision"
  map.connect 'projects/:id/revisions/:revision/request_build', :controller => "build", :action => "request_build"
  map.connect 'projects/:id/revisions/:revision/builds/:build', :controller => "build", :action => "status"
  map.connect 'projects/:id/revisions/:revision/builds/:build/stderr', :controller => "build", :action => "stderr"
  map.connect 'projects/:id/revisions/:revision/builds/:build/stdout', :controller => "build", :action => "stdout"

  map.connect 'projects/:id/browse/:path', :controller => 'files', :action => "browse"
  map.connect 'projects/:id/browse', :controller => 'files', :action => "browse", :path => ""
  
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id' #'
end
