require 'ftools'
require 'damagecontrol/scm/CVS'

include DamageControl

class TestDriver

  attr_reader :basedir
  attr_reader :cvs
  
  def initialize
    @basedir = File.expand_path("../../target/acceptance_#{Time.now.to_i}")
    @cvs = CVS.new
    File.mkpath(basedir)
    Dir.chdir(basedir)
  end

  def check_out_cvs_project(scm_spec, cvs_module)
    cvs.checkout("#{scm_spec}:#{cvs_module}", basedir) {|progress| puts progress}
    Dir.chdir(basedir)
  end
  
  def create_file(file, content)
    File.mkpath(File.dirname(file))
    File.open(file, "w") { |io| io.print(content) }
  end
  
  def commit_cvs_project(project, message)
    cvs.commit(project, message) {|progress| puts progress}
  end
    
end
