module DamageControl
	module FileUtils
		def mkdirs(dirs)
			dir = ""
			dirs.split("\\").each{|entry|
				dir += entry
				Dir.mkdir(dir) unless FileTest::exists?(dir)
				dir += "/"
			}
		end
		
		def delete(item)
			delete_directory(item) if FileTest::directory?(item) && !is_special_filename(item)
			File.delete(item) if FileTest::file?(item)
		end
		
		def delete_directory(dir)
			Dir.foreach(dir) do |file|  delete_file_in_dir(dir, file) end
			Dir.delete(dir)
		end
		
		def delete_file_in_dir(dir, filename)
			delete("#{dir}/#{filename}") unless is_special_filename(filename)
		end

		def is_special_filename(filename)
			filename == '.' || filename == '..'
		end
	end
end