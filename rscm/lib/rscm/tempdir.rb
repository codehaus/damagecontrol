require 'fileutils'

module RSCM
  def new_temp_dir(suffix="", basedir=File.dirname(__FILE__) + "/../../target")
    identifier = identifier.to_s
    identifier.gsub!(/\(|:|\)/, '_')
    dir = "#{basedir}/temp_#{identifier}_#{Time.new.to_i}#{suffix}"
    FileUtils.mkdir_p(dir)
    dir
  end
  module_function :new_temp_dir
end