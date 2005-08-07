require 'rscm/parser'
require 'rscm/revision'

module RSCM

  class SubversionLogParser
    def initialize(io, url)
      @io = io
      @revision_parser = SubversionLogEntryParser.new(url)
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

    def initialize(url)
      super(/^------------------------------------------------------------------------/)
      @url = url
    end

    def parse(io, skip_line_parsing=false, &line_proc)
      # We have to trim off the last newline - it's not meant to be part of the message
      revision = super
      revision.message = revision.message[0..-2] if revision
      revision
    end

    def relative_path(url, repo_path)
      url_tokens = url.split('/')
      repo_path_tokens = repo_path.split('/')
      
      max_similar = repo_path_tokens.length
      while(max_similar > 0)
        url = url_tokens[-max_similar..-1]
        path = repo_path_tokens[0..max_similar-1]
        if(url == path)
          break
        end
        max_similar -= 1
      end
      if(max_similar == 0) 
        nil
      else
        repo_path_tokens[max_similar..-1].join("/")
      end
    end
    
  protected

    def parse_line(line)
      if(@revision.nil?)
        parse_header(line)
      elsif(line.strip == "")
        @parse_state = :parse_message
      elsif(line =~ /Changed paths/)
        @parse_state = :parse_files
      elsif(@parse_state == :parse_files)
        file = parse_file(line)
        if(file)
          previously_added_file = @revision[-1]
          if(previously_added_file)
            # remove previous revision_file it if it's a dir
            previous_tokens = previously_added_file.path.split("/")
            current_tokens = file.path.split("/")
            current_tokens.pop
            if(previous_tokens == current_tokens)
              @revision.pop
            end
          end
          @revision << file
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
      @revision.identifier = revision.strip[1..-1].to_i unless revision.nil?
      @revision.developer = developer.strip unless developer.nil?
      @revision.time = parse_time(time.strip) unless time.nil?
    end
    
    def parse_file(line)
      file = RevisionFile.new
      path_from_root = nil
      if(line =~ /^   [M|A|D|R] ([^\s]+) \(from (.*)\)/)
        path_from_root = $1
        file.status = RevisionFile::MOVED
      elsif(line =~ /^   ([M|A|D|R]) (.+)$/)
        status = $1
        path_from_root = $2
        file.status = STATES[status]
      else
        raise "could not parse file line: '#{line}'"
      end

      path_from_root.gsub!(/\\/, "/")
      path_from_root = path_from_root[1..-1]
      rp = relative_path(@url, path_from_root)
      return if rp.nil?
      file.path = rp

      
#      if(@path.length+1 == path_from_root.length)
#        file.path = path_from_root[@path.length+1..-1]
#      else
#        file.path = path_from_root[@path.length+2..-1]
#      end

      file.native_revision_identifier =  @revision.identifier
      # http://jira.codehaus.org/browse/DC-204
      file.previous_native_revision_identifier = file.native_revision_identifier.to_i - 1;
      file
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
