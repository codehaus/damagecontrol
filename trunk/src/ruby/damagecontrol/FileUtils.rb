module DamageControl
	module FileUtils
		def delete(dir)
			if FileTest::exist?(dir)
				Dir.foreach(dir) {|filename| 
					File.delete(dir + "/" + filename) unless is_special_filename(filename) 
				}
				Dir.delete(dir)
			end
		end
	end
end