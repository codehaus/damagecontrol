module DamageControl

	class Hub
		attr_reader :last_message 
		
		def publish_message(message)
			@last_message=message
		end
	end

end