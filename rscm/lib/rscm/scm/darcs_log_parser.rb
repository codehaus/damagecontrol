require 'rscm'
require 'time'
require 'stringio'
require 'rexml/document'

module RSCM
  class DarcsLogParser
    def parse_revisions(io, from_identifier=Time.epoch, to_identifier=Time.infinity)
      revisions = Revisions.new

      doc = REXML::Document.new(io)

      path_revisions = {}
      doc.elements.each("//patch") do |element|
        revision = parse_revision(element.to_s, path_revisions)
        if ((from_identifier <= revision.time) && (revision.time <= to_identifier))
          revisions.add(revision)
        end
      end

      revisions.each do |revision|
        revision.each do |change|
          current_index = path_revisions[change.path].index(change.revision)
          change.previous_native_revision_identifier = path_revisions[change.path][current_index + 1]
        end
      end

      revisions
    end

    def parse_revision(revision_io, path_revisions)
      revision = Revision.new

      doc = REXML::Document.new(revision_io)

      doc.elements.each("patch") do |element|
        revision.native_revision_identifier =  element.attributes['hash']
        revision.developer = element.attributes['author']
        revision.time = Time.parse(element.attributes['local_date'])
        revision.message = element.elements["comment"].text
        revision.message.lstrip!
        revision.message.rstrip!

        element.elements["summary"].elements.each("add_file") do |file|
          add_changes(revision, file.text.strip, RevisionFile::ADDED, path_revisions)
        end
        element.elements["summary"].elements.each("modify_file") do |file|
          add_changes(revision, file.text.strip, RevisionFile::MODIFIED, path_revisions)
        end
      end

      revision
    end

  private

    def add_changes(revision, path, state, path_revisions)
      revision << RevisionFile.new(path, state, revision.developer, nil, revision.identifier, revision.time)

      path_revisions[path] ||= []
      path_revisions[path] << revision.identifier
    end
  end
end

