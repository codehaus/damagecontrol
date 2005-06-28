require 'yaml'
require 'rscm/revision'
require 'rscm/abstract_scm'

module DamageControl
  module Visitor
    # Visitor that saves each Revision in a folder with the name
    # of each Revision's +identifier+.
    #
    # Is also able to load revisions.
    #
    class YamlPersister

      def initialize(revisions_dir)
        @revisions_dir = revisions_dir
      end

      def visit_revisions(revisions)
      end

      def visit_revision(revision)
        revision_file = "#{@revisions_dir}/#{revision.identifier.to_s}/revision.yaml"
        dir = File.dirname(revision_file)
        FileUtils.mkdir_p(dir)
        File.open(revision_file, "w") do |io|
          YAML::dump(revision, io)
        end
      end

      def visit_file(file)
      end

    #### Non-visitor methods (for loading)

      # Loads +prior+ number of revisions upto +last_revision_identifier+.
      # +last_revision_identifier+ should be the dirname of the folder containing 
      # the last revision.
      #
      def load_upto(last_revision_identifier, prior)
        Log.info "Loading #{prior} revisions from #{@revisions_dir} (from #{last_revision_identifier} and down)"
        ids = identifiers
        last = ids.index(last_revision_identifier)
        revisions = RSCM::Revisions.new
        return revisions unless last

        first = last - prior + 1
        first = 0 if first < 0

        ids[first..last].each do |identifier|
          revision_yaml = "#{@revisions_dir}/#{identifier.to_s}/revision.yaml"
          Log.info "Loading revisions from #{revision_yaml}"
          begin
            revision = YAML::load_file(revision_yaml)
            revisions.add(revision)
            revision.each do |file|
              file.revision = revision
            end
          rescue Exception => e
            # Sometimes the yaml files get corrupted
            Log.error "Error loading revisions file: #{File.expand_path(revision_yaml)}"
            # Todo: delete it and schedule it for re-retrieval somehow.
          end
        end
        revisions
      end

      # Returns a sorted array of Time or int representing the revision directories.
      #
      def identifiers
        # This is pretty quick - even with a lot of directories.
        # TODO: the method is called 5 times for a page refresh!
        dirs = Dir["#{@revisions_dir}/*"].find_all {|f| File.directory?(f) && File.exist?("#{f}/revision.yaml")}
        # Turn them into ints so they can be sorted.
        dirs.collect { |dir| File.basename(dir).to_identifier }.sort
      end

      # Returns the identifier of the latest revision.
      #
      def latest_identifier
        identifiers[-1]
      end
    end
  end
end
