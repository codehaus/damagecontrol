require 'rscm/revision'
require 'rscm/abstract_log_parser'

require 'ftools'

module RSCM

  class CvsLogParser < AbstractLogParser
    REVISION_SEPARATOR = /^----------------------------$/ unless defined? REVISION_SEPARATOR
    ENTRY_SEPARATOR = /^=============================================================================$/ unless defined? ENTRY_SEPARATOR
    
    attr_accessor :cvspath
    attr_accessor :cvsmodule
    
    def initialize(io)
      super(io)
      @log = ""
    end
  
    def parse_revisions
      revisions = Revisions.new
      while(log_entry = next_log_entry)
        @log<<log_entry
        @log<<""
        begin
          parse_files(log_entry, revisions)
        rescue Exception => e
          $stderr.puts("could not parse log entry: #{log_entry}\ndue to: #{e.message}\n\t")
          $stderr.puts(e.backtrace.join("\n\t"))
        end
      end
      revisions.sort!
    end
    
    def next_log_entry
      read_until_matching_line(ENTRY_SEPARATOR)
    end
    
    def split_entries(log_entry)
      entries = [""]
      log_entry.each_line do |line|
        if line=~REVISION_SEPARATOR
          entries << ""
        else
          entries[entries.length-1] << line
        end
      end
      entries
    end
    
    def parse_files(log_entry, revisions)
      entries = split_entries(log_entry)

      entries[1..entries.length].each do |entry|
        file = parse_file(entry)
        next if file.nil?
        file.path = parse_path(entries[0])

        file.status = RevisionFile::ADDED if file.native_revision_identifier =~ /1\.1$/

        revision = revisions.add(file)
        # CVS doesn't have revision for revisions, use
        # Fisheye-style revision
#        revision.native_revision_identifier =  "MAIN:#{file.developer}:#{file.time.utc.strftime('%Y%m%d%H%M%S')}" if revision
      end
      nil
    end
    
    def parse_head_revision(first_entry)
      head_revision = extract_match(first_entry, /^head: (.*?)$/m)
    end
    
    def parse_path(first_entry)
      working_file = extract_match(first_entry, /^Working file: (.*?)$/m)
      return convert_all_slashes_to_forward_slashes(working_file) unless working_file.nil? || working_file == ""
      make_relative_to_module(extract_required_match(first_entry, /^RCS file: (.*?)(,v|$)/m))
    end
    
    def make_relative_to_module(file)
      return file if cvspath.nil? || cvsmodule.nil? || file.nil?
      cvspath = convert_all_slashes_to_forward_slashes(self.cvspath)
      convert_all_slashes_to_forward_slashes(file).gsub(/^#{cvspath}\/#{cvsmodule}\//, "")
    end
    
    def parse_file(file_entry)
      raise "can't parse: #{file_entry}" if file_entry =~ REVISION_SEPARATOR
         
      file_entry_lines = file_entry.split(/\r?\n/)
      file = RevisionFile.new

      file.native_revision_identifier =  extract_match(file_entry_lines[0], /revision (.*)$/)
      
      file.previous_native_revision_identifier = determine_previous_native_revision_identifier(file.native_revision_identifier)
      file.time = parse_cvs_time(extract_required_match(file_entry_lines[1], /date: (.*?)(;|$)/))
      file.developer = extract_match(file_entry_lines[1], /author: (.*?);/)
      
      state = extract_match(file_entry_lines[1], /state: (.*?);/)
      file.status = STATES[state]
      
      message_start = 2
      branches = nil
      if(file_entry_lines[2] =~ /^branches:\s+(.*);/)
        message_start = 3
        branches = $1
      end

      file.message = file_entry_lines[message_start..-1].join("\n")
         
      # Ignore the initial revision from import - we will have two of them
      if(file.message == "Initial revision" && branches == "1.1.1")
        return nil
      end

      file
    end
    
    def determine_previous_native_revision_identifier(revision)
      if revision =~ /(.*)\.(.*)/
        big_version_number = $1
        small_version_number = $2.to_i
        if small_version_number == 1
          nil
        else
          "#{big_version_number}.#{small_version_number - 1}"
        end
      else
        nil
      end
    end
    
    def parse_cvs_time(time)
      # 2003/11/09 15:39:25
      Time.utc(time[0..3], time[5..6], time[8..9], time[11..12], time[14..15], time[17..18])
    end
    
    def extract_required_match(string, regexp)
      if string=~regexp
        return($1)
      else
        $stderr.puts("can't parse: '#{string}'\nexpected to match regexp: #{regexp.to_s}")
      end
    end
    
    def extract_match(string, regexp)
      if string=~regexp
        return($1)
      else
        ""
      end
    end
    
  private
  
    # The state field is "Exp" both for added and modified files. retards!
    # We need some additional logic to figure out whether it is added or not.
    # Maybe look at the revision. (1.1 means new I think. - deal with it later)
    STATES = {"dead" => RevisionFile::DELETED, "Exp" => RevisionFile::MODIFIED} unless defined? STATES

  end

end
