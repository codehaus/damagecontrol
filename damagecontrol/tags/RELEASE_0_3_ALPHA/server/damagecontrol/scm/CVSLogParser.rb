require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/Logging'
require 'damagecontrol/scm/AbstractLogParser'

require 'ftools'

module DamageControl

  class CVSLogParser < AbstractLogParser

    include Logging
    
    attr_accessor :cvspath
    attr_accessor :cvsmodule
    
    def initialize(io)
      super(io)
      @log = ""
    end
  
    def parse_changesets
      changesets = ChangeSets.new
      while(log_entry = next_log_entry)
        @log<<log_entry
        @log<<""
        begin
          parse_changes(log_entry, changesets)
        rescue Exception => e
          error("could not parse log entry: #{log_entry}\ndue to: #{format_exception(e)}")
        end
      end
      changesets
    end
    
    def next_log_entry
      read_until_matching_line(/====*/)
    end
    
    def split_entries(log_entry)
      entries = [""]
      log_entry.each_line do |line|
        if line=~/----*/
          entries << ""
        else
          entries[entries.length-1] << line
        end
      end
      entries
    end
    
    def parse_changes(log_entry, changesets)
      entries = split_entries(log_entry)

      entries[1..entries.length].each do |entry|
        change = parse_change(entry)
        change.path = parse_path(entries[0])

        change.status = Change::ADDED if change.revision =~ /1\.1$/

        changeset = changesets.add(change)
        # CVS doesn't have revision for changesets, use
        # Fisheye-style revision
        changeset.revision = "MAIN:#{change.developer}:#{change.time.utc.strftime('%Y%m%d%H%M%S')}" if changeset
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
    
    def parse_change(change_entry)
      raise "can't parse: #{change_entry}" if change_entry=~/-------*/
         
      change_entry = change_entry.split(/\r?\n/)
      change = Change.new

      change.revision = extract_match(change_entry[0], /revision (.*)$/)

      change.previous_revision = determine_previous_revision(change.revision)
      change.time = parse_cvs_time(extract_required_match(change_entry[1], /date: (.*?)(;|$)/))
      change.developer = extract_match(change_entry[1], /author: (.*?);/)
      
      state = extract_match(change_entry[1], /state: (.*?);/)
      change.status = STATES[state]
      change.message = change_entry[2..-1].join("\n") << "\n"
         
      change
    end
    
    def determine_previous_revision(revision)
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
        error("can't parse: #{string}\nexpected to match regexp: #{regexp.to_s}")
        ""
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
    STATES = {"dead" => Change::DELETED, "Exp" => Change::MODIFIED}

  end

end
