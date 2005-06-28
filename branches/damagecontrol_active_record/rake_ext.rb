# Rake extension for DamageControl. Modifications to the default Rakefile
# are kept here to make RoR upgrading easier. Only a few edits to Rakefile
# should be necessary after a RoR upgrade. To upgrade to a newer version of
# RoR, stand in this folder and run:
#
#    rails .
#
# When the project is upgraded to a new RoR (creating a new Rakefile),
# edit the Rakefile in the following way:
#
# 1) Add a require at the top after the others:
#    require 'rake_ext'
#
# 2) edit the line with: task :test_units => [ :clone_structure_to_test ] to:
#    task :test_units => [ :clean_target, :recreate_schema, :clone_structure_to_test ]
#
require 'rake'
require 'rake/tasklib'

module Rake
  class TestTask < TaskLib
    def initialize(name=:test)
      @name = name
      @libs = ["lib", "../../trunk/rscm/lib", "../../trunk/rscm/test"]
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
