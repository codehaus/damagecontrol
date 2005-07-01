# Rake extension for DamageControl. Modifications to the default Rakefile
# are kept here to make RoR upgrading easier. Only a few edits to Rakefile
# should be necessary after a RoR upgrade. To upgrade to a newer version of
# RoR, stand in this folder and run:
#
#    rails .
#
# Answer 'y' to all overwrite questions except:
#    config/database.yml
#
# When the project is upgraded to a new RoR (creating a new Rakefile),
# edit the Rakefile in the following way:
#
# 1) Add a require at the top after the others:
#    require 'rake_ext'
#
# 2) edit the :environment task to load 'dc_environment' instead of 'environment'
#
require 'rake'
require 'rake/tasklib'

LIBS = ["lib", "../../trunk/rscm/lib", "../../trunk/rscm/test"]
$: << LIBS.join(':')

module Rake
  class TestTask < TaskLib
    def initialize(name=:test)
      @name = name
      @libs = LIBS
      @pattern = nil
      @options = nil
      @test_files = nil
      @verbose = false
      @warning = false
      @loader = :rake
      yield self if block_given?
      @pattern = 'test/test*.rb' if @pattern.nil? && @test_files.nil?
      define
    end
  
  end
end

desc "Delete files generated during test"
task :clean_target do
  FileUtils.rm_rf 'target'
end

desc "Recreate the dev database from schema.sql"
task :recreate_schema => :environment do
  abcs = ActiveRecord::Base.configurations
  case abcs["development"]["adapter"]
    when "sqlite", "sqlite3"
      db = "#{abcs['development']['dbfile']}"
      File.delete(db) if File.exist?(db)
      `#{abcs[RAILS_ENV]["adapter"]} #{db} < db/schema.sql`
    else 
      raise "Unknown database adapter '#{abcs["test"]["adapter"]}'"
  end
end

desc "Run the DamageControl Webapp"
task :webapp do
  ruby "-I#{LIBS.join(':')} script/server"
end

desc "Run the DamageControl Daemon"
task :daemon do
  ruby "-I#{LIBS.join(':')} script/daemon"
end

desc "Create sample projects"
task :create_sample_projects do
  ruby "-I#{LIBS.join(':')} script/create_sample_projects"
end

desc "Recreate database, create sample projects and run daemon"
task :daemon_from_scratch => [:recreate_schema, :create_sample_projects, :daemon]