require File.dirname(__FILE__) + "/publisher/base.rb"

Dir[File.dirname(__FILE__) + "/publisher/*.rb"].each do |src|
  require src
end
