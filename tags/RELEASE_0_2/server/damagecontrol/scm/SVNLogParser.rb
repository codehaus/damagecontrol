require 'damagecontrol/scm/Changes'
require 'damagecontrol/scm/AbstractLogParser'
require 'damagecontrol/util/Logging'

module DamageControl
  
  class SVNLogParser < AbstractLogParser
    include Logging
  
    def initialize(io, prefix)
      super(io)
      @prefix = prefix
    end

    def next_log_entry
      read_until_matching_line(/^-+$/)
    end
    
    def parse_changesets
      changesets = ChangeSets.new
      while(log_entry = next_log_entry)
        begin
          changesets.add(parse_changeset(log_entry))
        rescue Exception => e
          error("could not parse log entry: #{log_entry}\ndue to: #{format_exception(e)}")
        end
      end
      changesets
    end
    
    def parse_changeset(log_entry)
      log_entry = log_entry.split("\n")
      
      changeset = ChangeSet.new
      revision, developer, time, the_rest = log_entry[0].split("|")
      changeset.revision = revision.strip
      changeset.developer = developer.strip
      changeset.time = parse_time(time.strip)
      
      # 3rd line to first empty line are changes
      log_entry[2..first_empty_line(log_entry) - 1].each do |change_line|
        changeset<<parse_change(changeset.revision, change_line)
      end
      # everything after first empty line is the message
      if first_empty_line(log_entry) == log_entry.size then
        changeset.message = ""
      else
        changeset.message = log_entry[first_empty_line(log_entry)+1..-1].join("\n") + "\n"
      end
      
      changeset
    end
    
    def parse_change(revision, change_line)
      change = Change.new
      change.revision = revision
      change.previous_revision = previous_revision(change.revision)
      if(change_line =~ /^ *\w (.*) \(from (.*)\)/)
        change.path = $1
        change.status = Change::MOVED
      elsif(change_line =~ /^ *(\w) (.*)$/)
        status, path = change_line.split
        change.path = path
        change.status = STATES[status]
      else
        raise "could not parse change line: #{change_line}"
      end
      change.path = make_relative(change.path)
      change
    end
    
    def make_relative(path)
      prefix = convert_all_slashes_to_forward_slashes(@prefix)
      convert_all_slashes_to_forward_slashes(path).gsub(/^\/#{prefix}\//, "")
    end
    
    def first_empty_line(log_entry)
      log_entry.each_index {|i| return i if log_entry[i].strip == "" }
      log_entry.size
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
