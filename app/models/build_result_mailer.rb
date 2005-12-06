class BuildResultMailer < ActionMailer::Base
  
  def self.headline(build)
    "#{build.revision.project.name}: #{build.state.name} build (#{build.reason_description})"
  end
  
  def build_result(recipients, from, build, stdout_tail, stderr_tail)
    self.recipients = recipients
    self.from = from
    self.body["build"] = build
    self.body["headline"] = BuildResultMailer.headline(build)
    self.body["stdout_tail"] = stdout_tail
    self.body["stderr_tail"] = stderr_tail

    self.subject = BuildResultMailer.headline(build)
    self.sent_on = Time.new.utc
    self.content_type = "text/html"

    logger.info("Sending email to #{recipients.inspect} via #{delivery_method}") if logger
  end
end
