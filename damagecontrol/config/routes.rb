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
  
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id' #'
end
