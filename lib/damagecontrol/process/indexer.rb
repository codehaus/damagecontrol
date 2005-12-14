module DamageControl
  module Process
    class Indexer < Base
      def run
        forever(10) do # We don't care about the projects here
          RevisionsScmFiles.index_unindexed_files!
        end
      end
    end
  end
end