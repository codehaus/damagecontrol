require 'yaml'
require 'rscm/changes'
require 'rscm/abstract_scm'

module DamageControl
  module Visitor
    # Visitor that saves each ChangeSet in a folder with the name
    # of each ChangeSet's +id+.
    #
    # Is also able to load changesets.
    #
    class YamlPersister

      def initialize(changesets_dir)
        @changesets_dir = changesets_dir
      end

      def visit_changesets(changesets)
      end

      def visit_changeset(changeset)
        changeset_file = "#{@changesets_dir}/#{changeset.id.to_s}/changeset.yaml"
        dir = File.dirname(changeset_file)
        FileUtils.mkdir_p(dir)
        File.open(changeset_file, "w") do |io|
          YAML::dump(changeset, io)
        end
      end

      def visit_change(change)
      end

    #### Non-visitor methods (for loading)

      # Loads +prior+ number of changesets upto +last_changeset_id+.
      # +last_changeset_id+ should be the dirname of the folder containing 
      # the last changeset.
      #
      def load_upto(last_changeset_id, prior)
        last = ids.index(last_changeset_id)

        changesets = RSCM::ChangeSets.new
        if(last)
          first = last - prior + 1
          first = 0 if first < 0

          ids[first..last].each do |id|
            changesets.add(YAML::load_file("#{@changesets_dir}/#{id.to_s}/changeset.yaml"))
          end
        end
        changesets
      end

      # Returns a sorted array of Time or int representing the changeset directories.
      #
      def ids
        # This is pretty quick - even with a lot of directories.
        # TODO: the method is called 5 times for a page refresh!
        dirs = Dir["#{@changesets_dir}/*"].find_all {|f| File.directory?(f) && File.exist?("#{f}/changeset.yaml")}
        # Turn them into ints so they can be sorted.
        dirs.collect { |dir| File.basename(dir).to_id }.sort
      end

      # Returns the id of the latest changeset.
      #
      def latest_id
        ids[-1]
      end
    end
  end
end
