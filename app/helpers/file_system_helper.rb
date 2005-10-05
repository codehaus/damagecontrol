module FileSystemHelper
  DEFAULT_ICON_PATH = '/images/filetypes/txt.gif' unless defined? DEFAULT_ICON_PATH

  def file_icon(file_name)
    icon_path = nil
    if(File.directory?(file_name))
      icon_path = "/images/filetypes/dir.gif"
    else
      icon_path = "/images/filetypes/#{File.extname(file_name)}.gif"
    end
    File.exist?(RAILS_ROOT + '/public' + icon_path) ? icon_path : DEFAULT_ICON_PATH
  end
end
