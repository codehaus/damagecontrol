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
  
  class StandardOutEvent < BuildEvent
    attr_reader :data
  
    def initialize(build, data)
      super(build)
      @data = data
    end

    def ==(event)
      super(event) && event.output == output
    end
  end

  class StandardErrEvent < BuildEvent
    attr_reader :data
  
    def initialize(build, data)
      super(build)
      @data = data
    end

    def ==(event)
      super(event) && event.data == data
    end
  end

  class BuildRequestEvent < BuildEvent
  end

  class BuildStartedEvent < BuildEvent
  end

  class BuildCompleteEvent < BuildEvent
  end

  class BuildStateChangedEvent < BuildEvent
  end

  class UserMessage
    attr_reader :message
    
    def initialize(message)
      @message = message
    end
  end

  class StatProducedEvent
    attr_reader :project_name
    attr_reader :xml_file

    def initialize(project_name, xml_file)
      @project_name, @xml_file = project_name, xml_file
    end
  end

end