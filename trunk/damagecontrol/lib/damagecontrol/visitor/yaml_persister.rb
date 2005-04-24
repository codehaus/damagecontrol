require 'yaml'
require 'rscm/changes'
require 'rscm/abstract_scm'

module DamageControl
  module Visitor
    # Visitor that saves each ChangeSet in a folder with the name
    # of each ChangeSet's +identifier+.
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
        changeset_file = "#{@changesets_dir}/#{changeset.identifier.to_s}/changeset.yaml"
        dir = File.dirname(changeset_file)
        FileUtils.mkdir_p(dir)
        File.open(changeset_file, "w") do |io|
          YAML::dump(changeset, io)
        end
      end

      def visit_change(change)
      end

    #### Non-visitor methods (for loading)

      # Loads +prior+ number of changesets upto +last_changeset_identifier+.
      # +last_changeset_identifier+ should be the dirname of the folder containing 
      # the last changeset.
      #
      def load_upto(last_changeset_identifier, prior)
        Log.info "Loading #{prior} changesets from #{@changesets_dir} (from #{last_changeset_identifier} and down)"
        ids = identifiers
        last = ids.index(last_changeset_identifier)
        changesets = RSCM::ChangeSets.new
        return changesets unless last

        first = last - prior + 1
        first = 0 if first < 0

        ids[first..last].each do |identifier|
          changeset_yaml = "#{@changesets_dir}/#{identifier.to_s}/changeset.yaml"
          Log.info "Loading changesets from #{changeset_yaml}"
          begin
            changesets.add(YAML::load_file(changeset_yaml))
          rescue Exception => e
            # Sometimes the yaml files get corrupted
            Log.error "Error loading changesets file: #{File.expand_path(changeset_yaml)}"
            # Todo: delete it and schedule it for re-retrieval somehow.
          end
        end
        changesets
      end

      # Returns a sorted array of Time or int representing the changeset directories.
      #
      def identifiers
        # This is pretty quick - even with a lot of directories.
        # TODO: the method is called 5 times for a page refresh!
        dirs = Dir["#{@changesets_dir}/*"].find_all {|f| File.directory?(f) && File.exist?("#{f}/changeset.yaml")}
        # Turn them into ints so they can be sorted.
        dirs.collect { |dir| File.basename(dir).to_identifier }.sort
      end

      # Returns the identifier of the latest changeset.
      #
      def latest_identifier
        identifiers[-1]
      end
    end
  end
end
