require 'yaml'
require 'fileutils'
require 'damagecontrol/core/Build'
require 'damagecontrol/scm/Changes'

module DamageControl

  # Custom high-performant serializer/deserializer for Build objects.
  # This class serializes Build objects to a directory.
  # We're using this serialization mechanism rather than YAML
  # so that parts of a build can be read quickly without the
  # overhead of opening and reading a file.
  class BuildSerializer
    include FileUtils

    def dump(build, build_dir)
      mkdir_p(build_dir)
      property_files = Dir["#{build_dir}/*=*"]
      property_files.each {|file| File.delete(file)}
      File.new("#{build_dir}/duration=#{build.duration}", File::CREAT).close if build.duration
      File.new("#{build_dir}/status=#{build.status}", File::CREAT).close if build.status
      File.new("#{build_dir}/label=#{build.label}", File::CREAT).close if build.label
      File.new("#{build_dir}/scm_commit_time=#{build.scm_commit_time.ymdHMS}", File::CREAT).close if build.scm_commit_time
      File.new("#{build_dir}/dc_start_time=#{build.dc_start_time.ymdHMS}", File::CREAT).close if build.dc_start_time
      File.open("#{build_dir}/changesets.yaml", File::CREAT | File::WRONLY) do |io|
       YAML::dump(build.changesets, io)
      end
    end
    
    def load(build_dir, with_changesets=false)
      project_name = File.basename(File.expand_path("#{build_dir}/../.."))
      build = Build.new(project_name)

      build.dc_creation_time = dc_creation_time(build_dir)
      build.duration         = duration(build_dir)
      build.status           = status(build_dir)
      build.label            = label(build_dir)
      build.scm_commit_time  = scm_commit_time(build_dir)
      build.dc_start_time    = dc_start_time(build_dir)
      build.changesets       = changesets(build_dir) if with_changesets
      build
    end
    
    def dc_creation_time(build_dir)
      Time.parse_ymdHMS(File.basename(build_dir))
    end

    def duration(build_dir)
      property_from_file(build_dir, "duration").to_i
    end

    def status(build_dir)
      property_from_file(build_dir, "status")
    end

    def label(build_dir)
      property_from_file(build_dir, "label")
    end

    def scm_commit_time(build_dir)
      time_from_file(build_dir, "scm_commit_time")
    end

    def dc_start_time(build_dir)
      time_from_file(build_dir, "dc_start_time")
    end
    
    def changesets(build_dir)
      # Sometimes YAML parsing fails - WTF?? (AH)
      # http://builds.codehaus.org/damagecontrol/private/project/damagecontrol?dc_creation_time=20041130053221
      # The bad file:
      # http://builds.codehaus.org/damagecontrol/private/root/damagecontrol/build/20041130053221/changesets.yaml
      changesets_file = "#{build_dir}/changesets.yaml"
      begin
        changesets = File.open(changesets_file) do |io|
          YAML::load(io)
        end
        changesets
      rescue Exception => e
        puts "Failed to parse changesets with YAML: #{changesets_file}"
        puts e.message
        puts e.backtrace.join("\n")
        ChangeSets.new
      end
    end

  private

    def time_from_file(build_dir, property_name)
      time = property_from_file(build_dir, property_name)
      time ? Time.parse_ymdHMS(time) : nil
    end
  
    def property_from_file(build_dir, property_name)
      file = Dir["#{build_dir}/#{property_name}=*"][0]
      if(file && File.basename(file) =~ /#{property_name}=(.*)/)
        $1
      else
        nil
      end
    end

  end
end
