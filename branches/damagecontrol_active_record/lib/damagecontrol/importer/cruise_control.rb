require 'rexml/document'
require 'rexml/xpath'

class Project < ActiveRecord::Base
  def import_from_cruise_control(io)
    doc = REXML::Document.new(io)
    
    self.name = REXML::XPath.first(doc, "//config/name" ).text
    
    REXML::XPath.each(doc, "*/*/*") do |e|
#      puts e.name
    end
  end
end