module DamageControl
	module FileUtils
		def mkdirs(dirs)
			dir = ""
			dirs.split(/\\|\//).each{|entry|
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

		alias :rmdir :delete

		def copy(from, to)
			from = File.expand_path(from)
			to = File.expand_path(to)
			if FileTest::directory?(to)
				to = "#{to}/#{File.basename(from)}"
				copy(from, to)
			else
				File.open(from) do |from_file|
					File.open(to, File::CREAT | File::WRONLY) do |to_file|
						to_file.puts(from_file.gets(nil))
					end
				end
			end
		end
		
		alias :cp :copy

		def is_special_filename(filename)
			filename == '.' || filename == '..'
		end
		
		def damagecontrol_home
			$damagecontrol_home || "../.."
		end
		
		# returns file relative damagecontrol-home
		def damagecontrol_file(filename)
			"#{damagecontrol_home}/#{filename}"
		end
	end
end