module RSCM
  # Represents the full history of a single file or directory.
  class HistoricFile
    attr_reader :relative_path
    
    def initialize(relative_path, directory, scm)
      raise "Not a String: '#{relative_path}' (#{relative_path.class.name})" unless relative_path.is_a? String
      @relative_path, @directory, @scm = relative_path, directory, scm
    end
    
    def directory?
      @directory
    end
    
    # Returns an Array of RevisionFile - from Time.epoch until Time.infinity (now)
    def revision_files
      @scm.revisions(Time.epoch, Time.infinity, @relative_path).collect do |revision|
        if revision.files.length != 1
          files_s = revision.files.collect{|f| f.to_s}.join("\n")
          raise "The file-specific revision didn't have exactly one file, but #{revision.files.length}:\n#{files_s}"
        end
        if(!revision.files[0].path.eql?(@relative_path))
          raise "The file-specific revision didn't have expected path '#{@relative_path}', but '#{revision.files[0].path}'"
        end
        revision.files[0]
      end
    end
    
    def children
      raise "Not a directory" unless directory?
      @scm.ls(@relative_path)
    end
  end
end