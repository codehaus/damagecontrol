class Pathname
  TYPES = Hash.new("application/octet-stream")
  DEFAULT_ICON_PATH = '/images/filetypes/txt.gif'

  def type
    TYPES[extname]
  end

  def icon
    icon_path = '/images/filetypes/#{extname}.gif'
    File.exist?(RAILS_ROOT + '/public' + icon_path) ? icon_path : DEFAULT_ICON_PATH
  end
end