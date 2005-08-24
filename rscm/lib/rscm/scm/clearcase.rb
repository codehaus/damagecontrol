require 'rscm/base'
require 'rscm/path_converter'
require 'fileutils'

module RSCM
  class ClearCase < Base
  
    LOG_FORMAT = "Developer:%u\\nTime:%Nd\\nExtendedName:%Xn\\nVersionId:%Vn\\nPreviousVersionId:%PVn\\nElementName:%En\\nOID:%On\\nO:%o\\nMessage:%Nc\\n------------------------------------------\\n"
  
    def revisions(checkout_dir, from_identifier, to_identifier=Time.infinity)
      result = Revisions.new
      with_working_dir(checkout_dir) do
        since = from_identifier.strftime("%d-%b-%Y.%H:%M:%S")
        cleartool("lshistory -recurse -nco -since #{since} -fmt #{LOG_FORMAT}") do |io|
          io.each_line {|l| puts l}
          revisions << Revision.new()
        end
      end
      result
    end
    
    def diff(checkout_dir, change)
      with_working_dir(checkout_dir) do
        cleartool("diff -diff_format #{change.path}@@#{change.previous_native_revision_identifier} #{change.path}@@#{change.revision}")
      end
    end

    def checked_out?(checkout_dir)
      File.exists?("#{checkout_dir}")
    end

    def uptodate?(checkout_dir, from_identifier)
      if (!checked_out?(checkout_dir))
        false
      else
        with_working_dir(checkout_dir) do
          false
        end
      end
    end

    def commit(checkout_dir, message)

    end
    
    def import
      # clearfsimport -preview -recurse -nsetevent <from> <to>
    end

  protected

    # Checks out silently. Called by superclass' checkout.
    def checkout_silent(checkout_dir, to_identifier)
      with_working_dir(checkout_dir) do
        cleartool("update .") { |io|
          #io.each_line {|l| puts l}
        }
      end
    end

    # Administrative files that should be ignored when counting files.
    def ignore_paths
      return [/.*\.updt/]
    end

  private
  
    def cleartool(cleartool_cmd)
      cmd = "cleartool #{cleartool_cmd}"
      Better.popen(cmd, "r+") do |io|
        if(block_given?)
          return(yield(io))
        else
          # just read stdout so we can exit
          io.read
        end
      end
    end
  
  end
end
