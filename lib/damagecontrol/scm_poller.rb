module DamageControl
  
  # Polls SCMs for new revisions and persists them in the database. Also updates the Ferret
  # index, which is the backbone for searching.
  class ScmPoller
    include Ferret::Document

    cattr_accessor :logger

    # Polls for new revisions in the SCM and persists them.
    # The latest revision is returned.
    def poll_and_persist_new_revisions(project)
      if(project.scm)
        rscm_revisions = project.scm.poll_new_revisions(project.latest_revision)
        revisions = nil
        unless rscm_revisions.length == 0
          revisions = persist_revisions(project, rscm_revisions)
          index!(project, rscm_revisions)
        end
        revisions ? revisions[-1] : nil
      end
    end
    
    # Stores revisions in the database and returns the persisted revisions.
    def persist_revisions(project, rscm_revisions)
      logger.info "Persisting #{rscm_revisions.length} new revisions for #{project.name}" if logger
      position = project.revisions.length
      
      # There may be a lot of inserts. Doing it in one txn will speed it up
      Revision.transaction do
        rscm_revisions.collect do |rscm_revision|
          rscm_revision.project_id = project.id
          rscm_revision.position = position
          position += 1

          # This will go on the web and scrape issue summaries. Might take a little while....
          # TODO: Do this on demand in an ajax call?
          begin
            # TODO: parse patois messages here too.
            rscm_revision.message = project.tracker.markup(rscm_revision.message) if project.tracker
          rescue => e
            logger.warn "Error marking up issue summaries for #{project.name}: #{e.message}" if logger
          end
          # We're not doing:
          #   project.revisions.create(revision)
          # because of the way Revision.create is implemented (overridden).
          revision = Revision.create(rscm_revision)
          rscm_revision.id = revision.id # just needed for the ferret indexing
          revision
        end
      end
    end
    
    # Updates the ferret index with revision and file contents
    def index!(project, rscm_revisions)
      persistent_index = FerretConfig::get_index(:create_if_missing => true)
      # TODO: index into ram and then persist with add_indexes (faster)
      # TODO: use primary keys
      rscm_revisions.each do |rscm_revision|
        ram_index = Ferret::Index::Index.new
        
        puts "Indexing revision #{rscm_revision.id} with #{rscm_revision.length} files"
        revision_doc = Document.new
        revision_doc << Field.new("id", rscm_revision.id, Field::Store::YES, Field::Index::UNTOKENIZED)
        revision_doc << Field.new("type", "r", Field::Store::YES, Field::Index::UNTOKENIZED)
        revision_doc << Field.new("developer", rscm_revision.developer, Field::Store::NO,  Field::Index::UNTOKENIZED)
        revision_doc << Field.new("message", rscm_revision.message, Field::Store::NO,  Field::Index::TOKENIZED)
        ram_index << revision_doc

        rscm_revision.files.each do |rscm_revision_file|
          unless rscm_revision_file.status == RSCM::RevisionFile::DELETED
            puts "Indexing revision_file #{rscm_revision_file.id}"

            file_doc = Document.new
            file_doc << Field.new("id", rscm_revision_file.id, Field::Store::YES, Field::Index::UNTOKENIZED)
            file_doc << Field.new("type", "f", Field::Store::YES, Field::Index::UNTOKENIZED)
            file_doc << Field.new("path", rscm_revision_file.path, Field::Store::YES, Field::Index::TOKENIZED)
            rscm_revision_file.open(project.scm) do |io|
              file_doc << Field.new("file_content", io.read, Field::Store::NO,  Field::Index::TOKENIZED)
            end
            ram_index << file_doc
          end
        end
        
        persistent_index.add_indexes(ram_index)
      end
      
      puts "Indexing done"
    end

  end
end
