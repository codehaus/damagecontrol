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
      @in_queue = Queue.new
      @consumers = []
      @shutdown = Object.new
    end

    #
    # Puts a message on the input queue. Messages will be popped off
    # this queue and delivered to on_message by a separate thread,
    # provided the space has been started.
    #
    def add(o)
      @in_queue.push(o)
    end

    # 
    # Starts the thread that pops off the input queue and delivers
    # to on_message
    #
    def start
      @run = true
      @in_queue_popper = Thread.new do
        while(true)
          o = @in_queue.pop
          break if o == @shutdown
          on_message(o)
        end
      end
    end
    
    #
    # Stops the popping thread, even if there are more messages in the input queue
    #
    def shutdown
      add(@shutdown)
    end    

    def on_message(o)
      raise "Subclasses must implement on_message(o)"
    end
  end

  #
  # A MulticastSpace is capable of multicasting messages to an array
  # of other spaces.
  #
  class MulticastSpace < Space
    def initialize(*args)
      super
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
        consumer.add(o)
      end
    end
  end

end