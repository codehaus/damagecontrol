module RSCM
  # Represents the full history of a single file
  class HistoricFile
    def initialize(relative_path, scm)
      @relative_path, @scm = relative_path, scm
    end
    
    # Returns an Array of RevisionFile - from Time.epoch until Time.infinity (now)
    def revision_files
      @scm.revisions(Time.epoch, Time.infinity, @relative_path).collect do |revision|
        if revision.files.length != 1
          files_s = revision.files.collect{|f| f.to_s}.join("\n")
          raise "The file-specific revision didn't have exactly one file, but #{revision.files.length}:\n#{files_s}"
        end
        if(revision.files[0].path != @relative_path)
          raise "The file-specific revision didn't have expected path #{@relative_path}, but #{revision.files[0].path}"
        end
        revision.files[0]
      end
    end
  end
end