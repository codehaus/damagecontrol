require 'thread'

module DamageControl
	class Latch
		def initialize
			@closed = true
			@mutex = Mutex.new
			@cv = ConditionVariable.new
		end
    
    def closed?
      @closed
    end
		
		def wait
			if @closed
				@mutex.synchronize {
					Thread.pass # technically this shouldn't be here, but sporadic deadlocks show up otherwise
					if @closed
						@cv.wait(@mutex)
					end
				}
			end
		end
		
		def release
			@closed = false
			@mutex.synchronize {
				@cv.broadcast
			}
		end
	end
end