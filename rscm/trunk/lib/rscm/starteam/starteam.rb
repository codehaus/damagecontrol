require 'fileutils'
require 'rscm/changes'
require 'rscm/abstract_scm'
require 'yaml'

class Time
  def to_rfc2822
    utc.strftime("%a, %d %b %Y %H:%M:%S +0000")
  end
end

module RSCM
  class StarTeam < AbstractSCM

    def changesets(checkout_dir, from_identifier, to_identifier=nil, files=nil)
      # just assuming it is a Time for now, may support labels later.
      from = from_identifier.to_rfc2822
      to = to_identifier.to_rfc2822

      # we're not really using the StarTeam class at this time, but the DummyScm class instead.
      clazz = "org.rubyforge.rscm.TestScm"
#      clazz = "org.rubyforge.rscm.starteam.StarTeam"
      # the java class really wants rfc822 and not rfc2822, but this works ok anyway.
      cmd = "java -classpath ext/rscm.jar org.rubyforge.rscm.Main \"#{from}\" \"#{to}\" . #{clazz} mooky snoopy"
      IO.popen(cmd) do |io|
        YAML::load(io)
      end
    end
  end
end
