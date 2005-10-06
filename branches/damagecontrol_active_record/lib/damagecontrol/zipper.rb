require 'zip/zipfilesystem'
require 'rake'

module DamageControl  
  class Zipper

    # Zips a directory to a zipfile, ignoring .svn, CVS
    # and other ignoreable files. Relative +exclude_patterns+ can
    # be used to narrow down what's zipped.
    #
    def zip(dirname, zipfile_name, exclude_patterns=[])
      dirname = File.expand_path(dirname)
      files = Rake::FileList.new
      files.include(dirname + "/**/*")
      exclude_patterns.each { |p| files.exclude(dirname + "/" + p) }

      Zip::ZipFile.open(zipfile_name, Zip::ZipFile::CREATE) do |zipfile|
        files.to_a.each do |file_name|
          relative_filename = file_name[dirname.length+1..-1]
          zipfile.add(relative_filename, file_name)
        end
        yield zipfile if block_given?
      end
    end

  end
end