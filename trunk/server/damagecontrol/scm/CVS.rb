require 'ftools'
require 'stringio'
require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/CVSLogParser'
require 'damagecontrol/scm/Changes'

module DamageControl

  # Handles parsing of CVS roots, checkouts and installation of trigger scripts
  #
  # If pserver is used, the user is assumed to already be authenticated with cvs login
  # prior to starting damagecontrol. (TODO: fix that!) 
  class CVS < AbstractSCM
  
    attr_reader :cvsroot
    
    def initialize(config_map)
      super(config_map)
      @cvsroot = config_map["cvsroot"] || required_config_param("cvsroot")
      @mod = config_map["cvsmodule"] || required_config_param("cvsmodule")
    end
    
    def protocol
      parse_cvsroot[0]
    end

    def user
      parse_cvsroot[1]
    end

    def host
      parse_cvsroot[2]
    end

    def path
      parse_cvsroot[3]
    end

    def mod
      @mod
    end
    
    def web_url_to_change(change)
      view_cvs_url = config_map["view_cvs_url"]
      return "root/#{config_map['project_name']}/checkout/#{mod}/#{change.path}" if view_cvs_url.nil? || view_cvs_url == "" 
      
      view_cvs_url_patched = "#{view_cvs_url}/" if(view_cvs_url && view_cvs_url[-1..-1] != "/")
      url = "#{view_cvs_url_patched}#{change.path}"
      url << "?r1=#{change.revision}&r2=#{change.previous_revision}" if(change.previous_revision)
      url
    end
    
    def changesets(from_time, to_time)
      # exclude commits that occured on from_time
      from_time = from_time + 1

      command = changes_command(from_time, to_time)
      log = ""
      yield command if block_given?
      cvs(working_dir, command) do |io|
        io.each_line do |line|
          log << line
          yield line if block_given?
        end
      end

      parser = CVSLogParser.new(StringIO.new(log))
      parser.cvspath = path
      parser.cvsmodule = mod
      parser.parse_changesets
    end
    
    def changes_command(from_time, to_time)
      # https://www.cvshome.org/docs/manual/cvs-1.11.17/cvs_16.html#SEC144
      # -N => Suppress the header if no revisions are selected.
      # -S => Do not print the list of tags for this file.
      "log -N -S -d\"#{cvsdate(from_time)}<=#{cvsdate(to_time)}\""
    end
    
    def cvsdate(time)
      return "" unless time
      # CVS wants all dates as UTC.
      time.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
    end
    
    def commit(message, &proc)
      cvs(working_dir, commit_command(message), &proc)
    end

    def commit_command(message)
      "commit -m \"#{message}\""
    end
    
    def time_option(time)
      if time.nil? then "" else "-D \"#{cvsdate(time)}\"" end
    end

    def checkout_command(time)
      "-d#{@cvsroot} checkout #{time_option(time)} #{mod}"
    end

    def update_command(time)
      "-d#{@cvsroot} update #{time_option(time)} -d -P"
    end
    
    def checkout(time = nil, &proc)
      if(checked_out?)
        cvs(working_dir, update_command(time), &proc)
      else
        cvs(checkout_dir, checkout_command(time), &proc)
      end
    end
    
    def working_dir
      "#{checkout_dir}/#{mod}"
    end
    
    # Installs and activates the trigger script in the repository
    # for a certain module. Upon subsequent checkins, the damage
    # control server will be notified over a socket and start
    # building
    #
    # @param project_name a human readable name for the module
    # @param dc_url where the dc server is running
    #
    # @block &proc a block that can handle the output (should typically log to file)
    #
    def install_trigger(
      project_name, \
      dc_url="http://localhost:4712/private/xmlrpc", \
      &proc
    )
      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout(&proc)
      with_working_dir(cvsroot_cvs.working_dir) do
        # install trigger command
        File.open("loginfo", File::WRONLY | File::APPEND) do |file|
          trigger_command = trigger_command(project_name, dc_url)
          file.puts("#{mod} #{trigger_command}")
        end

        # install trigger script
        File.open(trigger_script_name, "w") do |io|
          io.puts(trigger_script)
        end
        system("cvs -d#{@cvsroot} add #{trigger_script_name}")

        checkoutlist = File.open("checkoutlist", File::WRONLY | File::APPEND) do |file|
          file.puts(File.basename(trigger_script_name))
        end

        system("cvs commit -m \"Installed CamageControl nudger for #{project_name}\"")
      end
    end
    
    def trigger_script
%{require 'xmlrpc/client'

url = ARGV[0]
project_name = ARGV[1]

puts "Nudging DamageControl on \#{url} to build project \#{project_name}"
client = XMLRPC::Client.new2(url)
build = client.proxy("build")
result = build.trig(project_name, Time.now.utc.strftime("%Y%m%d%H%M%S"))
puts result
}
    end
    
    def create_cvsroot_cvs
      CVS.new("cvsroot" => @cvsroot, "cvsmodule" => "CVSROOT", "checkout_dir" => checkout_dir)
    end

    def trigger_installed?(project_name)
      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout
      loginfo_file = File.new(File.join(cvsroot_cvs.working_dir, "loginfo"))
      loginfo_content = loginfo_file.read
      loginfo_file.close
      trigger_in_string?(loginfo_content, project_name)
    end

    def uninstall_trigger(project_name)
      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout
      loginfo_file = File.new(File.join(cvsroot_cvs.working_dir, "loginfo"))
      loginfo_content = loginfo_file.read
      loginfo_file.close
      modified_loginfo = disable_trigger_from_string(loginfo_content, project_name, Time.new.utc)
      loginfo_file = File.new(File.join(cvsroot_cvs.working_dir, "loginfo"), "w")
      loginfo_file.write(modified_loginfo)
      loginfo_file.close
      with_working_dir(cvsroot_cvs.working_dir) do
        system("cvs commit -m \"Disabled DamageControl nudger for #{project_name}\"")
      end
    end

    def trigger_in_string?(loginfo_content, project_name)
      disable_trigger_from_string(loginfo_content, project_name, Time.new.utc) != loginfo_content
    end
    
    def disable_trigger_from_string(loginfo_content, project_name, date)
      modified = ""
      loginfo_content.each_line do |line|
        # TODO: couldn't find out how to express this with a single regexp.
        matches = (Regexp.new(".*ruby.*dctrigger.rb http.* #{project_name}$") =~ line) && line[0..0] != "#"
        # The old format - we want to match them to so they get deleted.
        matches = (Regexp.new("^cat .* | nc.*4711$") =~ line) && line[0..0] != "#" unless matches
        if(matches)
          formatted_date = date.strftime("%B %d, %Y")
          modified << "# Disabled by DamageControl on #{formatted_date}\n"
          modified << "##{line}"
        else
          modified << line
        end
      end
      modified
    end
    
    def conf_script(conf_file_name)
      to_os_path("#{path}/CVSROOT/#{conf_file_name}")
    end
    
    def checked_out?
      rootcvs = File.expand_path("#{working_dir}/CVS/Root")
      File.exists?(rootcvs)
    end
        
    def trigger_script_name
      "dctrigger.rb"
    end
    
    def trigger_command(project_name, dc_url)
      "#{ruby_path} " + to_os_path("#{path}/CVSROOT/#{trigger_script_name}") + " #{dc_url} #{project_name}"
    end
    
    def ruby_path
      if(windows?)
        "ruby"
      else
        "/home/services/dcontrol/ruby/bin/ruby"
#        "ruby"
      end
    end
    
    def cvs(dir, cmd, &proc)
      cmd = "cvs -q #{cmd} 2>&1"
      cmd_with_io(dir, cmd) do |io|
        io.each_line do |progress|
          if block_given? then yield progress else logger.debug(progress) end
        end
      end
    end

  private

    # parses the cvsroot into tokens
    # [protocol, user, host, path]
    #
    def parse_cvsroot
      md = case
        when @cvsroot =~ /^:local:/   then /^:(local):(.*)/.match(@cvsroot)
        when @cvsroot =~ /^:ext:/     then /^:(ext):(.*)@(.*):(.*)/.match(@cvsroot)
        when @cvsroot =~ /^:pserver:/ then /^:(pserver):(.*)@(.*):(.*)/.match(@cvsroot)
      end
      result = case
        when @cvsroot =~ /^:local:/   then [md[1], nil, nil, md[2]]
        when @cvsroot =~ /^:ext:/     then md[1..4]
        when @cvsroot =~ /^:pserver:/ then md[1..4]
      end
    end

  end

  ##################################################################################
  # This is only used during testing
  ##################################################################################

  class LocalCVS < CVS
    def initialize(basedir, mod)
      super("cvsroot" => ":local:#{basedir}/cvsroot", "cvsmodule" => mod, "checkout_dir" => "#{basedir}/checkout")
      @cvsrootdir = "#{basedir}/cvsroot"
    end

    def create
      File.mkpath(@cvsrootdir)
      cvs(@cvsrootdir, "-d#{cvsroot} init")
    end

    def import(dir)
      modulename = File.basename(dir)
      cvs(dir, "-d#{cvsroot} import -m \"initial import\" #{modulename} VENDOR START")
    end

    # TODO: refactor. This is ugly!
    def add_or_edit_and_commit_file(relative_filename, content)
      existed = false
      with_working_dir(working_dir) do
        File.mkpath(File.dirname(relative_filename))
        existed = File.exist?(relative_filename)
        File.open(relative_filename, "w") do |file|
          file.puts(content)
        end
      end
      cvs(working_dir, "add #{relative_filename}") unless(existed)

      message = existed ? "editing" : "adding"

      cvs(working_dir, "com -m \"#{message} #{relative_filename}\"")
    end
  end
end
