module DamageControl

	module FileUtils
		def is_special_filename(filename)
			filename == '.' || filename == '..'
		end
		
		def delete(item)
			delete_directory(item) if FileTest::directory?(item) && !is_special_filename(item)
			File.rm_f(item) if FileTest::file?(item)
		end
		
		def delete_directory(dir)
			Dir.foreach(dir) do |file|  delete_file_in_dir(dir, file) end
			File.rm_f(dir)
		end
		
		def delete_file_in_dir(dir, filename)
			delete("#{dir}/#{filename}") unless is_special_filename(filename)
		end

		alias :rmdir :delete

		def damagecontrol_home
			File.expand_path($damagecontrol_home || "../..")
		end
		
		# returns file relative damagecontrol-home
		def damagecontrol_file(filename)
			"#{damagecontrol_home}/#{filename}"
		end

		# returns file relative target (used in build)
		def target_file(filename)
			damagecontrol_file("target/#{filename}")
		end
	end
end