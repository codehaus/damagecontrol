module DamageControl
  module ScmWeb
    class Base < Plugin
      become_parent
      attr_accessor :enabled
    end
  end
end

Dir[File.dirname(__FILE__) + "/*.rb"].each do |src|
  require src unless src == __FILE__
end
