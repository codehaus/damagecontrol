class Revision < ActiveRecord::Base
  belongs_to :project
  has_many :revision_files, :dependent => true
  has_many :builds, :order => "create_time", :dependent => true

  # identifier can be String, Numeric or Time (depending on the SCM), so we YAML it to the database to preserve type info.
  # We have to fool AR to do this by wrapping it in an array - serialize doesn't seem to work when the types differ.
  def identifier=(i)
    self[:identifier] = YAML::dump([i])
  end

  def identifier
     (YAML::load(self[:identifier]))[0]
  end
  
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
  
  def self.create(rscm_revision)
    revision = super(rscm_revision)

    rscm_revision.each do |rscm_file|
      revision.revision_files.create(rscm_file)
    end
    
    revision
  end

  # Syncs the working copy of the project with this revision.
  # If +needs_zip+ is true, also creates a zip file.
  def sync_working_copy(needs_zip, zipper = DamageControl::Zipper.new)
    logger.info "Syncing working copy for #{project.name} with revision #{identifier} ..." if logger
    project.scm.checkout(identifier) if project.scm
    logger.info "Done Syncing working copy for #{project.name} with revision #{identifier}" if logger
    zip(zipper) if needs_zip

    # Now update the project settings if this revision has a damagecontrol.yml file
    update_project_settings    
  end

  # Requests build(s) for this revision. How many builds are requested depends on
  # how many BuildExecutors (slave and/or local) are registered for the associated project.
  # A +triggering_build+ can be specified if the build is requested as a result of another
  # successful build (this is only used for reporting).
  def request_builds(reason, triggering_build=nil)
    project.build_executors.collect do |build_executor|
      build_executor.request_build_for(self, reason, triggering_build)
    end
  end

  # Environment variables to set when building this revision.
  def build_environment
    {
      "DAMAGECONTROL_BUILD_LABEL" => label.to_s,
      "PKG_BUILD" => label.to_s,
      "DAMAGECONTROL_CHANGED_FILES" => revision_files.collect{|f| f.path}.join(',')
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
        project.populate_from_hash(YAML.load_file(damagecontrol_yml_file))
        project.save
      rescue => e
        logger.error e.message if logger
      end
    end
  end
    
end

# Adaptation to make it possible to create an AR Revision
# from an RSCM one
class RSCM::Revision
  attr_accessor :project_id
  attr_accessor :position
  
  def stringify_keys!
  end
  
  def reject
    {
      "project_id" => project_id,
      "position" => position,
      "identifier" => identifier,
      "developer" => developer,
      "message" => message,
      "timepoint" => time
    }
  end
end