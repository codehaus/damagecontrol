module FerretConfig
  FileUtils.mkdir_p "#{DC_DATA_DIR}/index" unless File.exist? "#{DC_DATA_DIR}/index"
  
  def get_index(options)
    options[:path] = "#{DC_DATA_DIR}/index"
    Ferret::Index::Index.new(options)
  end
  module_function :get_index
end
