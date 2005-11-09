class DocController < ApplicationController
  append_before_filter :sidebar
  
  def damagecontrol_yml
    send_file(File.dirname(__FILE__) + '/../../damagecontrol.yml', :type => "text/plain", :disposition => "inline")
  end
 
private

  def sidebar
    @template_for_left_column = "doc/sidebar"
  end
  
end
