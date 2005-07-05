class Publisher < ActiveRecord::Base
  serialize :delegate
  
  def before_create
    self.enabling_states = [] unless enabling_states
  end

  def publish(build)
    state_class = build.state.class
    if(enabling_states.index(build.state.class))
      delegate.publish(build)
    end
  end
end
