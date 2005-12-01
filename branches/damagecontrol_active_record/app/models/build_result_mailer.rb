class BuildResultMailer < ActionMailer::Base
  
  def self.headline(build)
    "#{build.revision.project.name}: #{build.state.name} build (#{build.reason_description})"
  end
  
  def build_result(recipients, from, build)
    self.recipients = recipients
    self.from = from
    self.body["build"] = build
    self.body["headline"] = BuildResultMailer.headline(build)

    self.subject = BuildResultMailer.headline(build)
    self.sent_on = Time.new.utc
    self.content_type = "text/html"

    logger.info("Sending email to #{recipients.inspect} via #{delivery_method}") if logger
  end
end
