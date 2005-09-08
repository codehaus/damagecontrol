require 'test/unit'
require 'rscm/tempdir'
require 'rscm/path_converter'
require 'rscm/difftool'

module RSCM
  module Difftool
    # assertion method that reports differences as diff.
    # useful when comparing big strings
    def assert_equal_with_diff(expected, actual, temp_basedir=File.dirname(__FILE__) + "/../../target")
      diff(expected, actual, temp_basedir) do |diff_io|
        diff_string = diff_io.read
        assert_equal("", diff_string, diff_string)
      end
    end
    module_function :assert_equal_with_diff
  
    def diff(expected, actual, temp_basedir, &block)
      dir = RSCM.new_temp_dir("diff", temp_basedir)
    
      expected_file = "#{dir}/expected"
      actual_file = "#{dir}/actual"
      File.open(expected_file, "w") {|io| io.write(expected)}
      File.open(actual_file, "w") {|io| io.write(actual)}

      difftool = WINDOWS ? File.dirname(__FILE__) + "/../../bin/diff.exe" : "diff"
      IO.popen("#{difftool} #{RSCM::PathConverter.filepath_to_nativepath(expected_file, false)} #{RSCM::PathConverter.filepath_to_nativepath(actual_file, false)}") do |io|
        yield io
      end
    end
    module_function :diff

  end
end
