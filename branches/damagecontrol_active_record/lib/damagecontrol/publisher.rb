require 'damagecontrol/publisher/base'

class Class
  def <=>(o)
    name <=> o.name
  end
end

Dir[File.dirname(__FILE__) + "/publisher/*.rb"].each do |src|
  require src
end
