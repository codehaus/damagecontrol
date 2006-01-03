# THIS CODE IS NOT ACTIVE YET
# http://ostermiller.org/findcomment.html
# metric: ration of commented out code
module DamageControl
  module Task
    class CommentDetector
      C_STYLE = /((?:\/\*(?:[^*]|(?:\*+[^*\/]))*\*+\/)|(?:\/\/.*))/

      def detect(dir)
        Dir["#{dir}/**/*"].each do |f|
          if(File.file?(f))
            File.open(f) do |io|
              s = io.read
              s.scan(C_STYLE) do |c|
                yield f, c[0]
              end
            end
          end
        end
      end

    end
  end
end

if $0 == __FILE__
  last_file = nil
  DamageControl::Task::CommentDetector.new.detect(ARGV[0]) do |file, comment|
    if(comment =~ /;/)
      if(file != last_file)
        puts "++++++++++++++++ #{file} ++++++++++++++++"
        last_file = file
      end
      puts comment
    end
  end
end