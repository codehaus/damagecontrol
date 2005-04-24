require 'rscm/parser'
require 'rscm/revision'

module RSCM

  class SubversionLogParser
    def initialize(io, path, checkout_dir)
      @io = io
      @revision_parser = SubversionLogEntryParser.new(path, checkout_dir)
    end
    
    def parse_revisions(&line_proc)
      # skip over the first ------
      @revision_parser.parse(@io, true, &line_proc)
      revisions = Revisions.new
      while(!@io.eof?)
        revision = @revision_parser.parse(@io, &line_proc)
        if(revision)
          revisions.add(revision)
        end
      end
      revisions
    end
  end
  
  class SubversionLogEntryParser < Parser

    def initialize(path, checkout_dir)
      super(/^------------------------------------------------------------------------/)
      @path = path ? path : ""
      @checkout_dir = checkout_dir
    end

    def parse(io, skip_line_parsing=false, &line_proc)
      # We have to trim off the last newline - it's not meant to be part of the message
      revision = super
      revision.message = revision.message[0..-2] if revision
      revision
    end

  protected

    def parse_line(line)
      if(@revision.nil?)
        parse_header(line)
      elsif(line.strip == "")
        @parse_state = :parse_message
      elsif(line =~ /Changed paths/)
        @parse_state = :parse_changes
      elsif(@parse_state == :parse_changes)
        change = parse_change(line)
        if change
          # This unless won't work for new directories or if revisions are computed before checkout (which it usually is!)
          fullpath = "#{@checkout_dir}/#{change.path}"
          @revision << change unless File.directory?(fullpath)
        end
      elsif(@parse_state == :parse_message)
        @revision.message << line.chomp << "\n"
      end
    end

    def next_result
      result = @revision
      @revision = nil
      result
    end

  private
  
    STATES = {"M" => RevisionFile::MODIFIED, "A" => RevisionFile::ADDED, "D" => RevisionFile::DELETED} unless defined? STATES

    def parse_header(line)
      @revision = Revision.new
      @revision.message = ""
      revision, developer, time, the_rest = line.split("|")
      @revision.revision = revision.strip[1..-1].to_i unless revision.nil?
      @revision.developer = developer.strip unless developer.nil?
      @revision.time = parse_time(time.strip) unless time.nil?
    end
    
    def parse_change(line)
      change = RevisionFile.new
      path_from_root = nil
      if(line =~ /^   [M|A|D|R] ([^\s]+) \(from (.*)\)/)
        path_from_root = $1
        change.status = RevisionFile::MOVED
      elsif(line =~ /^   ([M|A|D|R]) (.+)$/)
        status = $1
        path_from_root = $2
        change.status = STATES[status]
      else
        raise "could not parse change line: '#{line}'"
      end

      path_from_root.gsub!(/\\/, "/")
      return nil unless path_from_root =~ /^\/#{@path}/
      if(@path.length+1 == path_from_root.length)
        change.path = path_from_root[@path.length+1..-1]
      else
        change.path = path_from_root[@path.length+2..-1]
      end
      change.revision = @revision.revision
      # http://jira.codehaus.org/browse/DC-204
      change.previous_revision = change.revision.to_i - 1;
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

    def adjust_offset(time, sign, offset)
      hour_offset = offset[0..1].to_i
      min_offset = offset[2..3].to_i
      sec_offset = 3600*hour_offset + 60*min_offset
      sec_offset = -sec_offset if(sign == "+")
      time += sec_offset
      time
    end
    
  end

end
