require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/Changes'
require 'ftools'

module DamageControl

  class CVSLogParser

    include Logging
    
    def initialize
      @current_line = 0
      @log = ""
      @had_error = false
    end
  
    def parse_changes_from_log(io)
      changes = []
      while(log_entry = read_log_entry(io))
        @log<<log_entry
        begin
          changes += parse_changes(log_entry)
        rescue Exception => e
          error("could not parse log entry: #{log_entry}\ndue to: #{format_exception(e)}")
        end
      end
      changes
    end
    
    def read_log_entry(io)
      read_until_matching_line(io, /====*/)
      
      #log_entry = ""
      #io.each_line do |line|
      #  @current_line += 1
      #  @log<<line
      #  return log_entry if line=~/====*/
      #  log_entry<<line
      #end
      #return nil
      
    end
    
    def read_until_matching_line(io, regexp)
      return nil if io.eof?
      result = ""
      io.each_line do |line|
        break if line=~regexp
        result<<line
      end
      if result.strip == ""
        read_until_matching_line(io, regexp) 
      else
        result
      end
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
    
    def parse_changes(log_entry)
      entries = split_entries(log_entry)

      path = parse_path(entries[0])
      if path.nil? return []
      
      changes = []
      
      entries[1..entries.length].each do |entry|
        change = parse_change(entry)
        change.path = path
        changes<<change
      end
      
      changes
    end
    
    def parse_path(first_entry)
      make_relative_to_module(extract_match(first_entry, /^RCS file: (.*?)(,v|$)/m))
    end
    
    attr_accessor :cvspath
    attr_accessor :cvsmodule
    
    def make_relative_to_module(file)
      return nil if file.nil?
      return file if cvspath.nil? || cvsmodule.nil?
      # clean away windows backslashes
      cvspath.gsub!(/\\/, "/")
      file.gsub(/\\/, "/").gsub(/^#{cvspath}\/#{cvsmodule}\//, "")
    end
    
    def parse_change(change_entry)
      raise "can't parse: #{change_entry}" if change_entry=~/-------*/
         
      change_entry = change_entry.split(/\r?\n/)
      change = Change.new
         
      change.revision = extract_match(change_entry[0], /revision (.*)/)
      change.previous_revision = determine_previous_revision(change.revision)
      change.time = parse_cvs_time(extract_required_match(change_entry[1], /date: (.*?)(;|$)/))
      change.developer = extract_match(change_entry[1], /author: (.*?);/)
      change.message = change_entry[2..-1].join("\n")
         
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
    
    def error(msg)
      @had_error=true
      logger.error(msg + "\ncurrent line: #{@current_line}\ncvs log:\n#{@log}#{format_backtrace(caller)}")
    end
    
    def had_error?
      @had_error
    end
    
  end

end
