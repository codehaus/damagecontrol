class Publisher < ActiveRecord::Base
  serialize :delegate
  serialize :enabling_states
  
  def before_create
    self.enabling_states = [] unless enabling_states
  end

  # Publishes +build+ to our delegate if +build+'s state is
  # among our +enabling_states+.
  def publish(build)
    if(enabling_states.collect{|state| state.class}.index(build.state.class))
      delegate.publish(build)
    end
  end
end
