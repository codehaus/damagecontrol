require 'fileutils'

module RSCM
  def new_temp_dir
    identifier = identifier.to_s
    identifier.gsub!(/\(|:|\)/, '_')
    dir = File.dirname(__FILE__) + "/../../target/temp_#{identifier}_#{Time.new.to_i}"
    FileUtils.mkdir_p(dir)
    dir
  end
  module_function :new_temp_dir
end