module DamageControl
  class BuildEvent
    attr_reader :build

    def initialize(build)
      @build = build
      fail "build cannot be null" if build.nil?
    end

    def ==(event)
      event.is_a?(self.class) && event.build == build
    end
  end
  
  class BuildProgressEvent < BuildEvent
    attr_reader :output
  
    def initialize(build, output)
      super(build)
      @output = output
    end

    def ==(event)
      super(event) && event.output == output
    end
  end

  class BuildErrorEvent < BuildEvent
    attr_reader :message
  
    def initialize(build, message)
      super(build)
      @message = message
    end

    def ==(event)
      super(event) && event.message == message
    end
  end

  class BuildStartedEvent < BuildEvent
  end

  class BuildCompleteEvent < BuildEvent
  end

  class UserMessage
    attr_reader :message
    
    def initialize(message)
      @message = message
    end
  end

  class DoCheckoutEvent
    attr_reader :project_name
    attr_reader :force_build

    def initialize(project_name, force_build)
      @project_name, @force_build = project_name, force_build
    end
  end

  # event to picked up by BuildScheduler, which will only build if force_build || !changesets_or_last_commit_time.nil?
  class CheckedOutEvent
    attr_reader :project_name
    attr_reader :changesets_or_last_commit_time
    attr_reader :force_build

    def initialize(project_name, changesets_or_last_commit_time, force_build)
      @project_name, @changesets_or_last_commit_time, @force_build = project_name, changesets_or_last_commit_time, force_build
    end
  end

  class XMLProducedEvent
    attr_reader :project_name
    attr_reader :xml_file

    def initialize(project_name, xml_file)
      @project_name, @xml_file = project_name, xml_file
    end
  end

end