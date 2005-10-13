class BuildExecutor < ActiveRecord::Base
  has_many :builds
  
  # The sole master instance
  def self.master_instance
    begin
      @local ||= find(1) 
    rescue ActiveRecord::RecordNotFound => e
      @local = create(:id => 1, :is_master => true, :description => "Master build executor")
    end
  end
  
  # Requests a build.
  def request_build_for(revision, reason, triggering_build)
    build = revision.builds.create(:reason => reason, :triggering_build => triggering_build)
    self.builds << build
    build
  end

end
