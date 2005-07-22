module DamageControl
  module Tracker
    
    # Tracker objects are responsible for interacting with issue trackers (bug trackers).
    # They know how to recognise issue identifiers in strings (typically from SCM commit
    # messages) and turn these into HTML links that point to the associated issue on an
    # issue tracker installation running somewhere else.
    class Base < Plugin
      become_parent
      attr_accessor :selected
    end
  end
end

Dir[File.dirname(__FILE__) + "/*.rb"].each do |src|
  require src unless src == __FILE__
end
