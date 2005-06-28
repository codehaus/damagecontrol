class Publisher < ActiveRecord::Base
  serialize :delegate

  def publish(build)
    self.delegate.publish(build)
  end
end
