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

  class BuildRequestEvent < BuildEvent
  end

  class BuildStartedEvent < BuildEvent
  end

  class BuildCompleteEvent < BuildEvent
  end

  class UserMessage < BuildEvent
    attr_reader :message
    
    def initialize(message)
      @message = message
    end
  end
end