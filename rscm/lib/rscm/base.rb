require 'fileutils'
require 'rscm/revision'
require 'rscm/path_converter'

module RSCM
  # This class defines the RSCM API. The documentation of the various methods
  # uses CVS and Subversion's terminology. (For example, checkout means 'get working copy',
  # not 'lock for private edit' as in ClearCase or VSS terminology).
  #
  # Concrete subclasses of this class provide an API to manage a local working copy
  # as well as an associated 'central' repository. The main responsibility is working
  # copy operations:
  #
  # * add
  # * checkout
  # * checked_out?
  # * diff
  # * edit
  # * move
  # * revisions
  # * uptodate?
  # * file
  # * destroy_working_copy
  #
  # In addition to operations related to working copies, the same instance should provide
  # methods to administer the working copy's associated 'central' repository. These are:
  #
  # * central_exists?
  # * create_central
  # * can_create_central?
  # * import_central
  # * install_trigger
  # * supports_trigger? / can_install_trigger?
  # * trigger_installed?
  # * trigger_mechanism
  # * uninstall_trigger
  #
  # Some methods are a bit fuzzy with respect to their relevance to the working copy or
  # the associated central repository, as it depends on the nature of the individual underlying 
  # SCMs. These methods are:
  #
  # * checkout_command_line
  # * label
  # * name
  # * transactional? / atomic?
  # * update_command_line
  #
  # Some of the methods in this API use +from_identifier+ and +to_identifier+.
  # These identifiers can be either a UTC Time (according to the SCM's clock)
  # or a String or Integer representing a label/revision 
  # (according to the SCM's native label/revision scheme).
  #
  # If +from_identifier+ or +to_identifier+ are +nil+ they should respectively default to
  # Time.epoch or Time.infinite.
  #
  # TODO: rename this superclass to 'Base'
  #
  class Base

# TODO: Make revisions yield revisions as they are determined, to avoid
# having to load them all into memory before the method exits. Careful not to
# use yielded revisions to do another scm hit - like get diffs. Some SCMs
# might dead lock on this. Implement a guard for that.
# TODO: Add some visitor support here too?

  public
  
    def checkout_dir=(dir)
      @checkout_dir = PathConverter.filepath_to_nativepath(dir, false)
    end
  
    def checkout_dir
      @checkout_dir
    end

    def to_yaml_properties
      props = instance_variables
      props.delete("@checkout_dir")
      props.sort!
    end

    # Destroys the working copy
    def destroy_working_copy
      FileUtils.rm_rf(checkout_dir) unless checkout_dir.nil?
    end

    # Whether the physical SCM represented by this instance exists.
    #
    def central_exists?
      # The default implementation assumes yes - override if it can be
      # determined programmatically.
      true
    end
    
    # Whether or not this SCM is transactional (atomic).
    #
    def transactional?
      false
    end
    alias :atomic? :transactional?

    # Creates a new 'central' repository. This is intended only for creation of 'central'
    # repositories (not for working copies). You shouldn't have to call this method if a central repository
    # already exists. This method is used primarily for testing of RSCM, but can also
    # be used if you *really* want to create a central repository. 
    # 
    # This method should throw an exception if the repository cannot be created (for
    # example if the repository is 'remote' or if it already exists).
    #
    def create_central
      raise "Not implemented"
    end
    
    # Destroys the central repository. Shuts down any server processes and deletes the repository.
    # WARNING: calling this may result in loss of data. Only call this if you really want to wipe 
    # it out for good!
    def destroy_central
    end

    # Whether a repository can be created.
    def can_create_central?
      false
    end

    # Adds +relative_filename+ to the working copy.
    def add(relative_filename)
    end

    # Schedules a move of +relative_src+ to +relative_dest+
    # Should not take effect in the central repository until
    # +commit+ is invoked.
    def move(relative_src, relative_dest)
    end

    # Recursively imports files from a +dir+ into the central scm
    def import_central(dir, message)
      raise "Not implemented"
    end

    # Open a file for edit - required by scms that check out files in read-only mode e.g. perforce
    def edit(file)
    end
    
    # Commit (check in) modified files.
    def commit(message)
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
    #
    def checkout(to_identifier=Time.infinity) # :yield: file
      # the OS doesn't store file timestamps with fractions.
      before_checkout_time = Time.now.utc - 1

      # We expect subclasses to implement this as a protected method (unless this whole method is overridden).
      checkout_silent(to_identifier)
      files = Dir["#{@checkout_dir}/**/*"]
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
  
    # Returns a Revisions object for the period specified by +from_identifier+ (exclusive, i.e. after)
    # and +to_identifier+ (inclusive). If +relative_path+ is specified, the result will only contain
    # revisions pertaining to that path.
    #
    def revisions(from_identifier, to_identifier=Time.infinity, relative_path=nil)
      # Should be overridden by subclasses
      revisions = Revisions.new
      revisions.add(
        Revision.new(
          "up/the/chimney",
          Revision::DELETED,
          "DamageControl",
          "The #{name} class doesn't\n" +
            "correctly implement the revisions method. This is\n" +
            "not a real revision, but a hint to the developer to go and implement it.\n\n" +
            "Do It Now!",
          "999",
          Time.now.utc
        )
      )
      revisions
    end
    
    # Returns a HistoricFile for +relative_path+
    def file(relative_path)
      HistoricFile.new(relative_path, self)
    end

    # Whether the working copy is in synch with the central
    # repository's revision/time identified by +identifier+. 
    # If +identifier+ is nil, 'HEAD' of repository should be assumed.
    #
    # TODO: rename to in_synch?
    def uptodate?(identifier)
      # Suboptimal algorithm that works for all SCMs.
      # Subclasses can override this to improve efficiency.
      
      revisions(identifier).empty?
    end

    # Whether the project is checked out from the central repository or not.
    # Subclasses should override this to check for SCM-specific administrative
    # files if appliccable
    def checked_out?
      File.exists?(@checkout_dir)
    end

    # Whether triggers are supported by this SCM. A trigger is a command that can be executed
    # upon a completed commit to the SCM.
    def supports_trigger?
      # The default implementation assumes no - override if it can be
      # determined programmatically.
      false
    end
    alias :can_install_trigger? :supports_trigger?

    # Descriptive name of the trigger mechanism
    def trigger_mechanism
      "Unknown"
    end

    # Installs +trigger_command+ in the SCM.
    # The +install_dir+ parameter should be an empty local
    # directory that the SCM can use for temporary files
    # if necessary (CVS needs this to check out its administrative files).
    # Most implementations will ignore this parameter.
    #
    def install_trigger(trigger_command, install_dir)
      raise "Not implemented"
    end

    # Uninstalls +trigger_command+ from the SCM.
    #
    def uninstall_trigger(trigger_command, install_dir)
      raise "Not implemented"
    end

    # Whether the command denoted by +trigger_command+ is installed in the SCM.
    #
    def trigger_installed?(trigger_command, install_dir)
      raise "Not implemented"
    end

    # The command line to run in order to check out a fresh working copy.
    #
    def checkout_commandline(to_identifier=Time.infinity)
      raise "Not implemented"
    end

    # The command line to run in order to update a working copy.
    #
    def update_commandline(to_identifier=Time.infinity)
      raise "Not implemented"
    end

    # Returns/yields an IO containing the unified diff of the change.
    # Also see RevisionFile#diff
    def diff(change, &block)
      return(yield("Not implemented"))
    end

    def ==(other_scm)
      return false if self.class != other_scm.class
      self.instance_variables.each do |var|
        return false if self.instance_eval(var) != other_scm.instance_eval(var)
      end
      true
    end

  protected

    # Takes an array of +absolute_paths+ and turns it into an array
    # of paths relative to +dir+
    # 
    def to_relative(dir, absolute_paths)
      dir = File.expand_path(dir)
      absolute_paths.collect{|p| File.expand_path(p)[dir.length+1..-1]}
    end

  end
end
