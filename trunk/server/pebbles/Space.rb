require 'thread'

module Pebbles

  #
  # A Space instance maintains an internal queue of messages that
  # can be popped off by a thread internal to the space. The
  # messages that are popped off are delivered to the on_message
  # method, which must be implemented by sub classes
  #
  class Space
    def initialize(*args)
      @mutex = Mutex.new
      @in_queue = Queue.new
      # Queue doesn't expose its internal array
      @queue = []
      @shutdown = Object.new
    end

    #
    # Puts a message on the input queue. Messages will be popped off
    # this queue and delivered to on_message by a separate thread,
    # provided the space has been started.
    #
    def put(o)
      raise "@mutex is nil. super was probably not called from subclass: #{self.class.name}" if @mutex.nil?
      @mutex.synchronize do
        @in_queue.push(o)
        @queue.push(o)
      end
    end

    # 
    # Starts the thread that pops off the input queue and delivers
    # to on_message
    #
    def start
      @in_queue_popper = Thread.new do
        while(true)
          o = @in_queue.pop
          @queue.shift
          break if o == @shutdown
          begin
            on_message(o)
          rescue => e
            puts e.message
            puts e.backtrace.join("\n")
          end
        end
      end
    end
    
    def clear
      @in_queue.clear
    end
    
    def empty?
      @in_queue.empty?
    end
    
    #
    # Stops the popping thread, even if there are more messages in the input queue
    #
    def shutdown
      put(@shutdown)
    end    

    def on_message(o)
      raise "Subclasses must implement on_message(o)"
    end
    
    def queue
      @mutex.synchronize do
        @queue.dup
      end
    end
  end
  
  class Timer < Space
    def initialize(tick_interval)
      super
      @secs = 0
      @tick_interval = tick_interval
      put(Time.new)
    end
  
    def on_message(o)
      sleep(1)
      @secs += 1
      tick if (@secs % @tick_interval == 0)
      put(@secs)
    end
    
    def tick
      raise "Subclasses must implement tick"
    end
  end

  #
  # A MulticastSpace is capable of multicasting messages to an array
  # of other spaces.
  #
  class MulticastSpace < Space
    def initialize(*args)
      super
      @consumers = []
    end

    #
    # Adds a "child" space where incoming messages will be delivered to.
    #
    def add_consumer(consumer)
      @consumers << consumer
      consumer
    end

    #
    # Called by the internal thread when a message is taken off 
    # the input queue. Don't call this message explicitly,
    # except when testing a subclass of Space.
    #
    def on_message(o)
      @consumers.each do |consumer|
        if(consumer.respond_to?(:put))
          consumer.put(o)
        else
          puts "WARNING: method put not implemented in #{consumer.class}"
        end
      end
    end
  end

end