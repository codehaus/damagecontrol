module DamageControl
	class SCM
		def handles_path?(path)
			false
		end
		
		# checks out (or updates) path to directory
		def checkout(path, directory)
			raise "can't check out #{path}"
		end
	end
end