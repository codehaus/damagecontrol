require 'rscm'
require 'time'
require 'stringio'

module RSCM
  class DarcsLogParser
    def parse_changesets(io, from_identifier=Time.epoch, to_identifier=Time.infinity)
      changesets = ChangeSets.new
      changeset_string = ""

      blank_lines = 0
      io.each_line do |line|
        if (line =~ /^\s*$/)
          blank_lines += 1
        end

        if (blank_lines == 2 or io.eof?)
          changeset = parse_changeset(StringIO.new(changeset_string))
          changesets.add(changeset)
          changeset_string = ""
          blank_lines = 0
        end

        changeset_string << line
      end
      changesets
    end

    def parse_changeset(changeset_io)
      changeset = ChangeSet.new
      state = nil

      changeset.revision = ''

      changeset_io.each_line do |line|
        if (line =~ /^(\S{3}) (\S{3}) ([\s|\d]\d) (\d\d):(\d\d):(\d\d) (...) (\d{4})  (.*)$/)
          month = $2
          day = $3
          hour = $4
          min = $5
          sec = $6
          year = $8
          changeset.developer = $9

          changeset.time = Time.utc(year, month, day, hour, min, sec)

          state = :message
        elsif (state == :message)
          if (line =~ /^\s*$/)
            state = :files if line =~ /^\s*$/
          elsif (changeset.message.nil?)
            changeset.message = ""
          elsif (changeset.message)
            changeset.message << line.lstrip unless line =~ /^ \* .*$/
          end
        elsif (state == :files)
          if (line =~ /^    (\S) (\S*).*$/)
            if ($1 == 'A')
              status = Change::ADDED
            elsif ($1 == 'M')
              status = Change::MODIFIED
            end
            file = $2

            changeset << Change.new(file[2, file.length], status, changeset.developer, nil, changeset.revision, changeset.time) unless line =~ /\/$/
          end
        end
      end

      changeset.message.chomp!
      changeset
    end
  end
end
