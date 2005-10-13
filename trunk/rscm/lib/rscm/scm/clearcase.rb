require 'rscm/base'
require 'rscm/path_converter'
require 'fileutils'
require 'tempfile'

module RSCM
  class ClearCase < Base
    register self

    LOG_FORMAT = "- !ruby/object:RSCM::RevisionFile\\n  developer: %u\\n  time: \\\"%Nd\\\"\\n  native_revision_identifier: %Vn\\n  previous_native_revision_identifier: %PVn\\n  path: %En\\n  status: %o\\n  message: \\\"%Nc\\\"\\n\\n"
    TIME_FORMAT = "%d-%b-%Y.%H:%M:%S"
    MAGIC_TOKEN = "9q8w7e6r5t4y"
    STATUSES = {
      "checkin" => RevisionFile::MODIFIED,
      "mkelem" => RevisionFile::ADDED,
      "rmelem" => RevisionFile::DELETED,
    }
    DEFAULT_CONFIG_SPEC = "element * CHECKEDOUT\nelement * /main/LATEST"

    attr_accessor :stream, :stgloc, :tag, :config_spec

    def initialize(stream=nil, stgloc=nil, tag=nil, config_spec=DEFAULT_CONFIG_SPEC)
      @stream, @stgloc, @tag, @config_spec = stream, stgloc, tag, config_spec
    end

    def revisions(from_identifier, to_identifier=Time.infinity, relative_path=nil)
      checkout unless checked_out?
      rules = load_rules
      vob = vob(rules[0])
      result = Revisions.new
      
      unless vob
        STDERR.puts "No vob found. Please set load rules in the view: #{checkout_dir}"
        return result 
      end
      with_working_dir(checkout_dir) do
        since = (from_identifier + 1).strftime(TIME_FORMAT)
        cmd = "cleartool lshistory -recurse -nco -since #{since} -fmt \"#{LOG_FORMAT}\" -pname #{vob}"
        Better.popen(cmd) do |io|
          # escape all quotes, except the one at the beginning and end. this is a bit ugly...
          raw_yaml = io.read
          fixed_yaml = raw_yaml.gsub(/^  message: \"/, "  message: #{MAGIC_TOKEN}")
          fixed_yaml = fixed_yaml.gsub(/\"\n\n/, "#{MAGIC_TOKEN}\n\n")
          fixed_yaml = fixed_yaml.gsub(/\"/, "\\\"")
          fixed_yaml = fixed_yaml.gsub(MAGIC_TOKEN, "\"")
 
          files = YAML.load(fixed_yaml)
          files.each do |file|
            file.path.gsub!(/\\/, "/")
            file.status = STATUSES[file.status]
            rev = revision(file.native_revision_identifier)
            if(rev && matches_load_rules?(rules, file.path))
              file.native_revision_identifier = rev
              file.previous_native_revision_identifier = revision(file.previous_native_revision_identifier)
              t = file.time
              # the time now has escaped quotes..
              file.time = Time.utc(t[2..5],t[6..7],t[8..9],t[11..12],t[13..14],t[15..16])
              file.message.strip!
              result.add(file)
            end
          end
        end
      end
      result
    end

    def checked_out?
      !Dir["#{checkout_dir}/*"].empty?
    end

    def destroy_working_copy
      Better.popen("cleartool rmview #{checkout_dir}") do |io|
        io.read
      end
    end
    
    def import_central(dir, message)
      Better.popen("clearfsimport -recurse -nsetevent #{dir} #{checkout_dir}") do |io|
        io.read
      end
    end
    
    ## Non-RSCM API methods

    def mkview!
       # Create view (working copy)
       mkview_cmd = "cleartool mkview -snapshot -stream #{@stream} -stgloc #{@stgloc} -tag #{@tag} #{@checkout_dir}"
       Better.popen(mkview_cmd) do |io|
         puts io.read
       end
    end

    def update_load_rules!
      Dir.chdir(checkout_dir) do
        # tempfile is broken on windows (!!)
        cfg_spec_file = "__rscm.cfgspec"
        config_spec_file = File.open(cfg_spec_file, "w") do |io|
          io.write(@config_spec)
        end

        setcs_cmd = "cleartool setcs #{cfg_spec_file}"
        Better.popen(setcs_cmd, "w") do |io|
          io.write "yes\n"
        end
      end
    end

    def catcs
      Dir.chdir(checkout_dir) do
        catcs_cmd = "cleartool catcs"
        Better.popen(catcs_cmd) do |io|
          yield io
        end
      end
    end

    def vob(load_rule)
      if(load_rule =~ /[\\\/]*([\w]*)/)
        $1
      else
        nil
      end
    end

    # What's loaded into view
    def load_rules
      result = []
      catcs do |io|
        io.each_line do |line|
          if(line =~ /^load[\s]*(.*)$/)
            return result << $1
          end
        end
      end
      result
    end

  protected

    def checkout_silent(to_identifier=nil)
      if(checked_out?)
        with_working_dir(checkout_dir) do
          Better.popen("cleartool update .") do |io|
            io.read
          end
        end
      else
        mkview!
 
        # Set load rules (by setting config spec)
        #update_load_rules!
      end
    end

    # Administrative files that should be ignored when counting files.
    def ignore_paths
      return [/.*\.updt/]
    end

  private

    def revision(s)
      if(s =~ /.*\\([\d]*)/)
        $1.to_i
      else
        nil
      end
    end

    def matches_load_rules?(rules, path)
      rules.each do |rule|
        rule.gsub!(/\\/, "/")
        return true if path =~ /#{rule[1..-1]}/
      end
      false
    end

  end
end