require 'damagecontrol/scm/Changes'

module DamageControl

  class SVNLogParser
    PARSING_CHANGES = 0
    PARSING_MESSAGE = 1
    
    def initialize(prefix)
      @path_regexp = Regexp.new("   (.) \/#{prefix}\/(.*)")
    end

    def parse_changesets_from_log(io)
      changesets = ChangeSets.new
      changeset = nil
      message = nil
      state = nil
      io.each do |line|
        if(line =~ /(r.*) \| (.*) \| (.*) \| (.*)/)
          changeset = ChangeSet.new
          changeset.revision = $1
          changeset.developer = $2
          changeset.time = parse_time($3)
        elsif(@path_regexp.match(line))
          change = Change.new
          change.revision = changeset.revision
          change.previous_revision = previous_revision(change.revision)
          status = $1
          path = $2
          if(path =~ /(.*) \(from (.*)\)/)
            change.path = $1
            change.status = Change::MOVED
          else
            change.path = path
            change.status = STATES[status]
          end
          changeset << change
          state = PARSING_CHANGES
        elsif(state == PARSING_CHANGES)
          state = PARSING_MESSAGE
          message = ""
        elsif(line =~ /------------------------------------------------------------------------/)
          if (changeset)
            changeset.message = message
            changesets.add(changeset)
            state = nil
          end
        elsif(state == PARSING_MESSAGE)
          message << line
        end
      end
      changesets
    end
    
  private
    STATES = {"M" => Change::MODIFIED, "A" => Change::ADDED, "D" => Change::DELETED}
  
    def parse_time(svn_time)
      if(svn_time =~ /(.*)-(.*)-(.*) (.*):(.*):(.*) (\+|\-)([0-9]*) (.*)/)
        year  = $1.to_i
        month = $2.to_i
        day   = $3.to_i
        hour  = $4.to_i
        min   = $5.to_i
        sec   = $6.to_i
        time = Time.utc(year, month, day, hour, min, sec)

        sign = $7
        offset = $8
        hour_offset = offset[0..1].to_i
        min_offset = offset[2..3].to_i
        sec_offset = 3600*hour_offset + 60*min_offset
        sec_offset = -sec_offset if(sign == "+")
        time += sec_offset
      else
        raise "unexpected time format"
      end
    end
    
    def previous_revision(revision)
      prev = revision[1..-1].to_i - 1
      "r#{prev}"
    end
  end

end
