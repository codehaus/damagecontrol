require 'set'

class RevisionsScmFiles < ActiveRecord::Base
  DATA_INDEX_FIELD = "data" unless defined? DATA_INDEX_FIELD

  include Ferret::Document

  belongs_to :revision
  belongs_to :scm_file
  
  def after_destroy
    DamageControl::Settings.index.delete(ferret_id)
  end
  
  # Indexes +limit+ unindexed files and marks them as indexed (to avoid reindexing)
  def self.index_unindexed_files!(limit = 20)
    unindexed_files = find(
      :all, 
      :limit => limit, 
      :conditions => ["ferret_id IS NULL AND AND directory = ? AND status != ?", true, false, RSCM::RevisionFile::DELETED]
    )
    
    unindexed_files.each_with_index do |rsm, i|
      rsm.ferret_id = true
      rsm.save
    end
  end

  def index
    return if status == RSCM::RevisionFile::DELETED
    return unless ferret_id.nil?
    
    logger.info "#{revision.project.name}: Indexing #{path}@#{native_revision_identifier}" if logger
    # extension = File.extname(revision_file.path)
    # memory_index = Ferret::Index::Index.new(:analyzer => SourceCodeAnalyzer.new(extension))

    file_doc = Document.new
    # Open a stream to the contents of the file for the particular revision and index it
    self.open do |io|
      data = io.read
      file_doc << Field.new(DATA_INDEX_FIELD, data, Field::Store::NO,  Field::Index::TOKENIZED)
      file_doc << Field.new("id", id, Field::Store::YES, Field::Index::UNTOKENIZED)
      file_doc << Field.new("project_id", revision.project.id, Field::Store::YES, Field::Index::UNTOKENIZED)
    end
    DamageControl::Settings.index << file_doc
    memory_index
  end

  # Returns/yields an IO containing the contents of this file, using the +scm+ this
  # file lives in. Important: This will only work if this instance was retrieved via
  # Revision#scm_files
  def open(&block)
    project.scm.open(self, &block)
  end

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
    @@index_searcher ||= Ferret::Search::IndexSearcher.new(DamageControl::Settings.index_dir)
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
  
  def self.find_by_path_or_contents(query)
    by_path = self.find(:all, :conditions => ["path LIKE ?", "%#{query}"])
    by_contents = self.find_by_contents(query)
    result = Set.new
    result += by_path
    result += by_contents
    result.to_a
  end
  
end
