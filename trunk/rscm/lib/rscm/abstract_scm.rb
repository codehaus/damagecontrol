require 'fileutils'
require 'rscm/changes'
require 'rscm/path_converter'
require 'rscm/annotations'

class String
  # Turns a String into a Time if possible
  def to_identifier
    if(self =~ /20\d\d\d\d\d\d\d\d\d\d\d\d/)
      # Assume it's a timestamp string - convert to time.
      Time.parse_ymdHMS(self)
    else
      self
    end
  end
end

class Time
  def to_s
    self.ymdHMS
  end
end

module RSCM
  # This class defines the RSCM API. The documentation of the various methods
  # uses CVS' terminology.
  #
  # Some of the methods in this API use +from_identifier+ and +to_identifier+.
  # These identifiers can be either a UTC Time (according to the SCM's clock)
  # or a String or Integer representing a label/revision 
  # (according to the SCM's native label/revision scheme).
  #
  # If +from_identifier+ or +to_identifier+ are +nil+ they should respectively default to
  # epoch or the infinite future.
  #
  # Most of the methods take a mandatory +checkout_dir+ - even if this may seem
  # unnecessary. The reason is that some SCMs require a working copy to be checked
  # out in order to perform certain operations. In order to develop portable code,
  # you should always pass in a non +nil+ value for +checkout_dir+.
  #
  class AbstractSCM
    include FileUtils

    @@classes = []
    def self.register(cls) 
      @@classes << cls unless @@classes.index(cls)
    end      
    def self.classes
      @@classes
    end

    # Load all sources under scm, so SCM classes can register themselves
    Dir[File.dirname(__FILE__) + "/scm/*.rb"].each do |src|
      load(src)
    end


# TODO: Make changesets yield changesets as they are determined, to avoid
# having to load them all into memory before the method exits. Careful not to
# use yielded changesets to do another scm hit - like get diffs. Some SCMs
# might dead lock on this. Implement a guard for that.
# TODO: Add some visitor support here too?

  public
  
    # Whether the physical SCM represented by this instance exists.
    #
    def exists?
      # The default implementation assumes yes - override if it can be
      # determined programmatically.
      true
    end
    
    # Whether or not this SCM is transactional (atomic).
    #
    def transactional?
      false
    end

    # Creates a new 'central' repository. This is intended only for creation of 'central'
    # repositories (not for working copies). You shouldn't have to call this method if a central repository
    # already exists. This method is used primarily for testing of RSCM, but can also
    # be used if you *really* want to create a central repository. 
    # 
    # This method should throw an exception if the repository cannot be created (for
    # example if the repository is 'remote' or if it already exists).
    #
    def create
    end

    # Whether a repository can be created.
    #
    def can_create?
      false
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
      # TODO: what do we need this for? If we need it, rename to revision?
    end

    # Open a file for edit - required by scms that checkout files in read-only mode e.g. perforce
    #
    def edit(file)
    end

    # Checks out or updates contents from a central SCM to +checkout_dir+ - a local working copy.
    # If this is a distributed SCM, this method should create a 'working copy' repository
    # if one doesn't already exist. Then the contents of the central SCM should be pulled into
    # the working copy.
    #
    # The +to_identifier+ parameter may be optionally specified to obtain files up to a
    # particular time or label. +to_identifier+ should either be a Time (in UTC - according to
    # the clock on the SCM machine) or a String - reprsenting a label or revision.
    #
    # This method will yield the relative file name of each checked out file, and also return
    # them in an array. Only files, not directories, should be yielded/returned.
    #
    # This method should be overridden for SCMs that are able to yield checkouts as they happen.
    # For some SCMs this is not possible, or at least very hard. In that case, just override
    # the checkout_silent method instead of this method (should be protected).
    def checkout(checkout_dir, to_identifier=Time.infinity) # :yield: file
      # the OS doesn't store file timestamps with fractions.
      before_checkout_time = Time.now.utc - 1

      # We expect subclasses to implement this as a protected method (unless this whole method is overridden).
      checkout_silent(checkout_dir, to_identifier)
      files = Dir["#{checkout_dir}/**/*"]
      added = []
      files.each do |file|
        added << file if File.mtime(file).utc > before_checkout_time
      end
      ignore_paths.each do |regex|
        added.delete_if{|path| path =~ regex}
      end
      added_file_paths = added.find_all do |path|
        File.file?(path)
      end
      relative_added_file_paths = to_relative(checkout_dir, added_file_paths)
      relative_added_file_paths.each do |path|
        yield path if block_given?
      end
      relative_added_file_paths
    end
  
    # Returns a ChangeSets object for the period specified by +from_identifier+ (exclusive, i.e. after)
    # and +to_identifier+ (inclusive).
    #
    def changesets(checkout_dir, from_identifier, to_identifier=Time.infinity)
      # Should be overridden by subclasses
      changesets = ChangeSets.new
      changesets.add(
        Change.new(
          "up/the/chimney",
          Change::DELETED,
          "DamageControl",
          "The #{name} SCM class doesn't\n" +
            "correctly implement the changesets method. This is\n" +
            "not a real changeset, but a hint to the developer to go and implement it.\n\n" +
            "Do It Now!",
          "999",
          Time.now.utc
        )
      )
      changesets
    end

    # Whether the working copy in +checkout_dir+ is in synch with the central
    # repository since +from_identifier+.
    #
    def uptodate?(checkout_dir, from_identifier)
      # Suboptimal algorithm that works for all SCMs.
      # Subclasses can override this to improve efficiency.
      
      changesets(checkout_dir, from_identifier).empty?
    end

    # Whether the project is checked out from the central repository or not.
    # Subclasses should override this to check for SCM-specific administrative
    # files if appliccable
    def checked_out?(checkout_dir)
      File.exists?(checkout_dir)
    end

    # Whether triggers are supported by this SCM. A trigger is a command that can be executed
    # upon a completed commit to the SCM.
    def supports_trigger?
      # The default implementation assumes no - override if it can be
      # determined programmatically.
      false
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
    def uninstall_trigger(trigger_command, install_dir)
    end

    # Whether the command denoted by +trigger_command+ is installed in the SCM.
    #
    def trigger_installed?(trigger_command, install_dir)
    end

    # The command line to run in order to check out a fresh working copy.
    #
    def checkout_commandline(to_identifier=Time.infinity)
    end

    # The command line to run in order to update a working copy.
    #
    def update_commandline(to_identifier=Time.infinity)
    end

    # Returns/yields an IO containing the unified diff of the change.
    def diff(checkout_dir, change, &block)
      return(yield("Diff not implemented"))
    end

    def ==(other_scm)
      return false if self.class != other_scm.class
      self.instance_variables.each do |var|
        return false if self.instance_eval(var) != other_scm.instance_eval(var)
      end
      true
    end

  protected

    # Takes an array of +absolute_paths+ and turn them into an array
    # of paths relative to +dir+
    # 
    def to_relative(dir, absolute_paths)
      dir = File.expand_path(dir)
      absolute_paths.collect{|p| File.expand_path(p)[dir.length+1..-1]}
    end

  end
end
