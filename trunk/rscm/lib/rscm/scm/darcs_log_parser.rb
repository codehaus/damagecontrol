require 'rscm'
require 'time'
require 'stringio'
require 'rexml/document'

module RSCM
  class DarcsLogParser
    def parse_changeset(changeset_io)
      changeset = ChangeSet.new
      changeset.revision = ''

      doc = REXML::Document.new changeset_io

      doc.elements.each("patch") { |element|
        changeset.revision = ''
        changeset.developer = element.attributes['author']
        changeset.time = Time.parse(element.attributes['local_date'])
        changeset.message = element.elements["comment"].text
        changeset.message.lstrip!
        changeset.message.rstrip!
      

        element.elements["summary"].elements.each("add_file") { |file|
          changeset << Change.new(file.text.strip, Change::ADDED, changeset.developer, nil, changeset.revision, changeset.time)
        }
        element.elements["summary"].elements.each("modify_file") { |file|
          changeset << Change.new(file.text.strip, Change::MODIFIED, changeset.developer, nil, changeset.revision, changeset.time)
        }
      }

      changeset
    end

    def parse_changesets(io, from_identifier=Time.epoch, to_identifier=Time.infinity)
      changesets = ChangeSets.new

      doc = REXML::Document.new io

      doc.elements.each("//patch") { |element|
        changeset = parse_changeset(element.to_s)
        if ((from_identifier <= changeset.time) && (changeset.time <= to_identifier))
          changesets.add(changeset)
        end
      }

      changesets
    end
  end
end

