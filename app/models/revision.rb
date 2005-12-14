class Revision < ActiveRecord::Base
  belongs_to :project
  has_and_belongs_to_many :scm_files
  has_many :builds, :order => "create_time", :dependent => true do
    def in_progress
      find(:all, :conditions => "exitstatus IS NULL")
    end
  end

  # Creates a new persistent Revision from a RSCM::Revision. Also
  # creates necessary ScmFile records and sets up associations.
  def self.create_from_rscm_revision(project, rscm_revision, position)
    revision = project.revisions.create(
      :position   => position,
      :identifier => rscm_revision.identifier,
      :developer  => rscm_revision.developer,
      :message    => rscm_revision.message,
      :timepoint  => rscm_revision.time
    )

    rscm_revision.each do |rscm_revision_file|
      # RSCM::RevisionFile is always a file, not a dir
      scm_file = ScmFile.find_or_create_by_path_and_directory_and_project_id(rscm_revision_file.path, false, project.id)
      revision.scm_files.push_with_attributes(
        scm_file, 
        :status                              => rscm_revision_file.status,
        :previous_native_revision_identifier => rscm_revision_file.previous_native_revision_identifier,
        :native_revision_identifier          => rscm_revision_file.native_revision_identifier,
        :timepoint                           => rscm_revision_file.time,
        :indexed                             => false
      )
    end
    
    revision
  end

  # Sets the identifier
  def identifier=(i)
    # identifier can be String, Numeric or Time (depending on the SCM), so we YAML it to the database to preserve type info.
    # We have to fool AR to do this by wrapping it in an array - serialize doesn't seem to work when the types differ.
    self[:identifier] = YAML::dump([i])
  end

  # Gets the identifier
  def identifier
     (YAML::load(self[:identifier]))[0]
  end
  
  # Base directory for filesystem data
  def basedir
    "#{project.basedir}/revision/#{id}"
  end

  # An integer that serves as a label. If the identifier is a Numeric (integer),
  # same as that - otherwise a custom counter.
  # The purpose of the label is simply to display a nicer label than the
  # revision identifier in the case where the identifier is not a Numeric
  # (but e.g. a Time, as it is with CVS).
  def label
    if(identifier.is_a?(Numeric))
      identifier
    elsif(position && project && project.initial_revision_label)
      position + project.initial_revision_label
    else
      nil
    end
  end
  
  # Syncs the working copy of the project with this revision.
  def sync_working_copy!(needs_zip, zipper = DamageControl::Zipper.new)
    project.prepare_scm
    logger.info "Syncing working copy for #{project.name} with revision #{identifier} ..." if logger
    project.scm.checkout(identifier) if project.scm
    logger.info "Done Syncing working copy for #{project.name} with revision #{identifier}" if logger
    #zip(zipper) if needs_zip

    # Now update the project settings if this revision has a damagecontrol.yml file
    update_project_settings    
  end

  # Requests and returns build(s) for this revision. How many builds are requested depends on
  # how many BuildExecutors (slave and/or local) are registered for the associated project.
  # A +triggering_build+ can be specified if the build is requested as a result of another
  # successful build (this is only used for reporting).
  #
  # If there are already unfinished build(s) for this revision, this method returns nil
  def request_builds(reason, triggering_build=nil)
    return nil unless builds.in_progress.empty?
    project.build_executors.collect do |build_executor|
      build_executor.request_build_for(self, reason, triggering_build)
    end
  end

  # Environment variables to set when building this revision.
  def build_environment
    {
      "DAMAGECONTROL_BUILD_LABEL" => label.to_s,
      "PKG_BUILD" => label.to_s,
      "DAMAGECONTROL_CHANGED_FILES" => scm_files.collect{|f| f.path}.join(',')
    }
  end

private
  
  # Makes a zip of the working copy and adds an XML file with metadata that can be read
  # by XStream (http://xstream.codehaus.org/). This will be read by build slaves
  # that are Java webstart (http://java.sun.com/products/javawebstart/) apps that 
  # can be downloaded from the DC server (not yet written).
  def zip(zipper)
    return unless project.scm && project.scm.checkout_dir 

    zipdir = project.scm.checkout_dir
    zipfile_name = project.zip_dir + "/#{label}.zip"
    File.delete(zipfile_name) if File.exist?(zipfile_name)
    
    # TODO use this when we have implemented 'array' editing in the web interface
    # excludes = project.generated_files
    excludes = []

    # TODO: use builder.
    zipper.zip(zipdir, zipfile_name, excludes) do |zipfile|
      zipfile.file.open("damagecontrol_build_info.xml", "w") do |f| 
        f.puts("<build-info>")
        f.puts("  <revision>")
        f.puts("    <id>#{id}</id>")
        f.puts("    <identifier>#{identifier}</identifier>")
        f.puts("    <label>#{label}</label>")
        f.puts("  </revision>")
        f.puts("  <buildcommand>#{project.build_command}</buildcommand>")
        f.puts("  <environment>")

        build_environment.each do |k, v|
          f.puts("    <entry>")
          f.puts("      <string>#{k}</string>")
          f.puts("      <string>#{v}</string>")
          f.puts("    </entry>")
        end

        f.puts("  </environment>")
        f.puts("</build-info>")
      end
    end    
  end

  def update_project_settings
    return unless project && project.scm
    damagecontrol_yml_file = File.join(project.scm.checkout_dir, "damagecontrol.yml")
    if(File.exist?(damagecontrol_yml_file))
      logger.info "Importing project settings from #{damagecontrol_yml_file}" if logger
      begin
        project.populate_from_hash(YAML.load_file(damagecontrol_yml_file), nil)
        project.save
      rescue => e
        logger.error e.message if logger
      end
    end
  end
    
end