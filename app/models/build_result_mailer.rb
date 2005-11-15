class BuildResultMailer < ActionMailer::Base
  def build_result(recipients, from, build)
    headline = "#{build.revision.project.name}: #{build.state.name} build (#{build.reason_description})"
    
    self.recipients = recipients
    self.from = from
    self.body["build"] = build
    self.body["headline"] = headline

    self.subject = headline
    self.sent_on = Time.new.utc
    self.content_type = "text/html"

    logger.info("Sending email to #{recipients.inspect} via #{delivery_method}") if logger
  end
end
