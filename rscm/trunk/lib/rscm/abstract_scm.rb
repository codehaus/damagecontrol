require 'fileutils'
require 'rscm/changes'
require 'xmlrpc/utils'

class Time
  class << self
    def epoch
      Time.at(0)
    end

    def infinity
      Time.utc(2038)
    end
  end
end

module RSCM
  # This class defines the RSCM API. The documentation of the various methods
  # uses CVS' terminology.
  #
  # Some of the methods in this API use +from_identifier+ and +to_identifier+.
  # These identifiers can be either a UTC Time (according to the SCM's clock)
  # or a String representing a label (according to the SCM's label system).
  #
  # If +from_identifier+ or +to_identifier+ are +nil+ they respectively represent
  # epoch or the infinite future.
  #
  # Most of the methods take a mandatory +checkout_dir+ - even if this may seem
  # unnecessary. The reason is that some SCMs require a working copy to be checked
  # out in order to perform certain operations. In order to develop portable code,
  # you should always pass in a non +nil+ value for +checkout_dir+.
  #
  class AbstractSCM
    include FileUtils
    
  public
  
    # Whether the physical SCM represented by this instance exists.
    #
    def exists?
      # The default implementation assumes yes - override if it can be
      # determined programmatically.
      true
    end

    # Creates a new repository. Throws an exception if the
    # repository cannot be created.
    #
    def create
    end

    # Whether a repository can be created.
    #
    def can_create?
    end

    # Recursively imports files from a directory
    #
    def import(dir, message)
    end

    # The display name of this SCM
    #
    def name
      # Should be overridden by subclasses to display a nicer name
      self.class.name
    end

    # Gets the label for the working copy currently checked out in +checkout_dir+.
    #
    def label(checkout_dir)
    end

    # Open a file for edit - required by scms that checkout files in read-only mode e.g. perforce
    #
    def edit(file)
    end

    # Checks out or updates contents from an SCM to +checkout_dir+ - a local working copy.
    #
    # The +to_identifier+ parameter may be optionally specified to obtain files up to a
    # particular time or label. +time_label+ should either be a Time (in UTC - according to
    # the clock on the SCM machine) or a String - reprsenting a label.
    #
    # This method will yield the relative file name of each checked out file, and also return
    # them in an array. Only files, not directories, will be yielded/returned.
    #
    def checkout(checkout_dir, to_identifier=Time.infinity) # :yield: file
      ["not/implemented/in", __FILE__, "do/it/now"]
    end
    
    # Returns a ChangeSets object for the period specified by +from_identifier+
    # and +to_identifier+. See AbstractSCM for details about the parameters.
    #
    def changesets(checkout_dir, from_identifier, to_identifier=Time.infinity, files=nil)
      # Should be overridden by subclasses
      changesets = ChangeSets.new
      changesets.add(
        Change.new(
          "up/the/chimney",
          "DamageControl",
          "The #{name} SCM class in #{__FILE__} doesn't\n" +
            "correctly implement the changesets method. This is\n" +
            "not a real changeset, but a hint to the developer to go and implement it.\n\n" +
            "Do It Now!",
          "999",
          Time.now.utc
        )
      )
      changesets
    end

    # Whether the working copy in +checkout_dir+ is uptodate with the repository
    # since +from_identifier+.
    #
    def uptodate?(checkout_dir, from_identifier)
      # Suboptimal algorithm that works for all SCMs.
      # Subclasses can override this to increase efficiency.
      
      changesets(checkout_dir, from_identifier).empty?
    end

    # Whether triggers are supported by this SCM
    def supports_trigger?
      # The default implementation assumes no - override if it can be
      # determined programmatically.
      false
    end

    # Whether the command denoted by +trigger_command+ is installed in the SCM.
    #
    def trigger_installed?(trigger_command, trigger_files_checkout_dir)
    end

    # Installs +trigger_command+ in the SCM.
    # The +install_dir+ parameter should be an empty local
    # directory that the SCM can use for temporary files
    # if necessary (CVS needs this to check out its administrative files).
    # Most implementations will ignore this parameter.
    #
    def install_trigger(trigger_command, install_dir)
    end

    # Uninstalls +trigger_command+ from the SCM.
    #
    def uninstall_trigger(trigger_command, trigger_files_checkout_dir)
    end

    # The command line to run in order to check out a fresh working copy.
    #
    def checkout_commandline(to_identifier=Time.infinity)
    end

    # The command line to run in order to update a working copy.
    #
    def update_commandline(to_identifier=Time.infinity)
    end

    def ==(other_scm)
      return false if self.class != other_scm.class
      self.instance_variables.each do |var|
        return false if self.instance_eval(var) != other_scm.instance_eval(var)
      end
      true
    end

    # The Javascript function that should be called when the page
    # is loaded, to initialise the web ui.
    def javascript_on_load
      ""
    end

  protected

    def with_working_dir(dir)
      prev = Dir.pwd
      begin
        mkdir_p(dir)
        Dir.chdir(dir)
        yield
      ensure
        Dir.chdir(prev)
      end
    end

  end
end
