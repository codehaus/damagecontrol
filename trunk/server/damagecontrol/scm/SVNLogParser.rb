require 'parsedate'
require 'pebbles/Parser'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/scm/AbstractLogParser'
require 'damagecontrol/util/Logging'

module DamageControl

  def adjust_offset(time, sign, offset)
    hour_offset = offset[0..1].to_i
    min_offset = offset[2..3].to_i
    sec_offset = 3600*hour_offset + 60*min_offset
    sec_offset = -sec_offset if(sign == "+")
    time += sec_offset
    time
  end

  class SVNLogParser
    def initialize(io, path)
      @io = io
      @changeset_parser = SVNLogEntryParser.new(path)
    end
    
    # we need to pass in dates, since the log may contain changes outside the desired dates.
    # this is because the svn log command strangely includes the first changeset before the start date.
    # this is probably an svn bug, or at least a very odd feature.
    def parse_changesets(start_date=nil, end_date=nil, &line_proc)
      # skip over the first ------
      @changeset_parser.parse(@io, true, &line_proc)
      changesets = ChangeSets.new
      while(!@io.eof?)
        changeset = @changeset_parser.parse(@io, &line_proc)
        if(changeset)
          after_required = start_date.nil? || start_date < changeset.time
          before_required = end_date.nil? || changeset.time <= end_date
          if(after_required && before_required)
            changesets.add(changeset)
          end
        end
      end
      changesets
    end
  end
  
  class SVNLogEntryParser < Pebbles::Parser
    include DamageControl

    def initialize(path)
      super(/^------------------------------------------------------------------------/)
      @path = path ? path : ""
    end

  protected

    def parse_line(line)
      if(@changeset.nil?)
        parse_header(line)
      elsif(line.strip == "")
        @parse_state = :parse_message
      elsif(line =~ /Changed paths/)
        @parse_state = :parse_changes
      elsif(@parse_state == :parse_changes)
        change = parse_change(line)
        @changeset << change
      elsif(@parse_state == :parse_message)
        @changeset.message << line.chomp << "\n"
      end
    end

    def next_result
      result = @changeset
      @changeset = nil
      result
    end

  private
  
    STATES = {"M" => Change::MODIFIED, "A" => Change::ADDED, "D" => Change::DELETED}

    def parse_header(line)
      @changeset = ChangeSet.new
      @changeset.message = ""
      revision, developer, time, the_rest = line.split("|")
      # we don't want the r
      @changeset.revision = revision.strip[1..-1] unless revision.nil?
      @changeset.developer = developer.strip unless developer.nil?
      @changeset.time = parse_time(time.strip) unless time.nil?
    end
    
    def parse_change(line)
      change = Change.new
      if(line =~ /^ *\w (.*) \(from (.*)\)/)
        change.path = $1
        change.status = Change::MOVED
      elsif(line =~ /^ *(\w) (.*)$/)
        status, path = line.split
        change.path = path
        change.status = STATES[status]
      else
        raise "could not parse change line: #{line}"
      end
      change.path = make_relative(change.path)
      change.revision = @changeset.revision
      # http://jira.codehaus.org/browse/DC-204
      change.previous_revision = "PREVIOUS_REVISION_UNKNOWN"
      change
    end

    def parse_time(svn_time)
      if(svn_time =~ /(.*)-(.*)-(.*) (.*):(.*):(.*) (\+|\-)([0-9]*) (.*)/)
        year  = $1.to_i
        month = $2.to_i
        day   = $3.to_i
        hour  = $4.to_i
        min   = $5.to_i
        sec   = $6.to_i
        time = Time.utc(year, month, day, hour, min, sec)
        
        time = adjust_offset(time, $7, $8)
      else
        raise "unexpected time format"
      end

    end
    
    def previous_revision(revision)
      prev = revision[1..-1].to_i - 1
      "r#{prev}"
    end

    def make_relative(change_path)
      prefix = @path.gsub(/\\/, "/")
      change_path.gsub(/\\/, "/").gsub(/^\/#{prefix}\//, "")
    end

  end

end
