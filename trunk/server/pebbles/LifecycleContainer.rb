module Pebbles

  class LifecycleContainer
    def initialize
      @components = []
    end
  
    def component(name, instance)
      self.class.module_eval("attr_accessor :#{name}")
      self.send("#{name}=", instance)
      @components << instance
      instance
    end

    def method_missing(symbol, *args)
      @components.each do |component|
        component.send(symbol) if(component.respond_to?(symbol))
      end
    end
  end

end