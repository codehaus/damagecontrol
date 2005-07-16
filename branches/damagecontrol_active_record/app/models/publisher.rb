class Publisher < ActiveRecord::Base
  serialize :delegate
  serialize :enabling_states
  
  def before_create
    self.enabling_states = [] unless enabling_states
  end

  # Publishes +build+ to our delegate if +build+'s state is
  # among our +enabling_states+.
  def publish(build)
    state_classes = enabling_states.collect do |state| 
      state.class
    end
    should_publish = state_classes.index(build.state.class)
    if(should_publish)
      delegate.publish(build)
    end
  end
end
