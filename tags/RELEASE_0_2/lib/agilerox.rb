require 'test/unit'

=begin
  Print each TestCase and test method as it is loaded by the interpreter
  Author: Dan North
=end

module Test
  module Unit
    class TestCase
      def TestCase.inherited(subclass) # intercept test cases
        printf "\n%s\n", subclass.to_s.sub(/^Test/, '').sub(/Test$/, '')
        modulename = ""
        classname = subclass.name
        if classname =~ /(.*)::(.*)/
          modulename = $1
          classname = $2
        end
        method_definition = <<-EOM
          def #{classname}.method_added(id) # intercept test methods
            meth = id.to_s
            printf("- %s\n", meth.sub(/^test_?/, '').gsub(/_/, ' ')) if meth =~ /^test/
          end
        EOM

        if modulename != ""
          eval <<-EOM
            module ::#{modulename}
              #{method_definition}
            end
          EOM
        else
          eval method_definition
        end
      end
    end
  end
end

# Load all the tests
if $0 == __FILE__
  ARGV.each { |test_file| require test_file }
  $stdout.flush
  exit! # avoid running tests at exit
end