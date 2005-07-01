class Publisher < ActiveRecord::Base
  cattr_accessor :logger
  serialize :delegate

  def publish(build)
    logger.info("Publishing build for #{build.revision.project.name} via #{delegate.name}")
    delegate.publish(build)
  end
end
