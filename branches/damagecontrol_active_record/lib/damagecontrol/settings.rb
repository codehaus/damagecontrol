module DamageControl
  module Settings
    
    # Returns the persistent Ferret index
    def index
      @@index ||= Ferret::Index::Index.new(
        :path => "#{DC_DATA_DIR}/index", 
        :create_if_missing => true,
        :auto_flush => true,
        :close_dir => true)
      )
    end
    module_function :index
  end
end