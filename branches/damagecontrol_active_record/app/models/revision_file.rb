class RevisionFile < ActiveRecord::Base
  include Ferret::Document

  belongs_to :revision
  
  def timepoint
    self[:timepoint] || revision.timepoint
  end

  # Finds instances by file contents. The results are either 
  # returned in an array or yielded one by one if a block is 
  # passed.
  #
  # The actual file contents is not stored in the RDBMS, so 
  # the search is using a Ferret index. This index can be updated
  # with index!
  def self.find_by_contents(query) #:yield: revision_file
    @@index_searcher ||= Ferret::Search::IndexSearcher.new(INDEX_DIR)
    @@query_parser   ||= Ferret::QueryParser.new(DATA_INDEX_FIELD, {})

    query = @@query_parser.parse(query)
    result = block_given? ? nil : [] 
    @@index_searcher.search_each(query) do |doc, score|
      id = @@index_searcher.reader.get_document(doc)["id"]
      if(block_given?) 
        yield self.find(id)
      else
        result << self.find(id)
      end
    end
    result
  end
  
  # Returns a Ferret index indexed with the contents of this file.
  # Invoking this method will open a connection to the SCM and may
  # be somewhat time consuming.
  def index
    logger.info "#{revision.project.name}: Indexing #{path}@#{native_revision_identifier}" if logger
    # extension = File.extname(revision_file.path)
    # memory_index = Ferret::Index::Index.new(:analyzer => SourceCodeAnalyzer.new(extension))

    memory_index = Ferret::Index::Index.new
    file_doc = Document.new
    # Open a stream to the contents of the file for the particular revision and index it
    self.open do |io|
      data = io.read
      file_doc << Field.new(DATA_INDEX_FIELD, data, Field::Store::NO,  Field::Index::TOKENIZED)
      file_doc << Field.new("id", id, Field::Store::YES, Field::Index::UNTOKENIZED)
      file_doc << Field.new("project_id", revision.project.id, Field::Store::YES, Field::Index::UNTOKENIZED)
    end
    memory_index << file_doc
    memory_index
  end

  # Returns/yields an IO containing the contents of this file, using the +scm+ this
  # file lives in.
  def open(&block)
    revision.project.scm.open(self, &block)
  end

  # TODO It's a bit hackish to embed view info in the model :-(
  ICONS = {
    RSCM::RevisionFile::ADDED => "document_new",
    RSCM::RevisionFile::DELETED => "document_delete",
    RSCM::RevisionFile::MODIFIED => "document_edit",
    RSCM::RevisionFile::MOVED => "document_exchange"
  } unless defined? ICONS

  DESCRIPTIONS = {
    RSCM::RevisionFile::ADDED => "New file",
    RSCM::RevisionFile::DELETED => "Deleted file",
    RSCM::RevisionFile::MODIFIED => "Modified file",
    RSCM::RevisionFile::MOVED => "Moved file"
  } unless defined? DESCRIPTIONS

  INDEX_DIR = "#{DC_DATA_DIR}/index/revision_files"
  DATA_INDEX_FIELD = "data"

  def icon
    ICONS[status]
  end

  def status_description
    DESCRIPTIONS[status]
  end


end

# Adaptation to make it possible to create an AR RevisionFile
# from an RSCM one
class RSCM::RevisionFile
  attr_accessor :revision_id
  
  def stringify_keys!
  end
  
  def reject
    {
      "revision_id" => revision_id,
      "status" => status,
      "path" => path,
      "previous_native_revision_identifier" => previous_native_revision_identifier,
      "native_revision_identifier" => native_revision_identifier,
      "timepoint" => time
    }
  end
end