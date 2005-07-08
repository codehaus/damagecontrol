Dir[File.dirname(__FILE__) + "/scm_web/*.rb"].each do |src|
  require src
end
