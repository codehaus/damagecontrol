require 'test/unit/assertions'

require 'TestDriver'

class TestStep
  attr_reader :task
  attr_reader :args

  def initialize(task, args)
    @task = task
    @args = args
  end
  
  def method_name
    task.downcase.gsub(/ /, '_')
  end
  
  def execute(driver)
    puts " - #{task}"
    driver.send(method_name, *args)
  end
end

class AcceptanceTest
  attr_reader :description
  attr_reader :steps

  def initialize(description)
    @description = description
    @steps = []
  end
  
  def run(driver)
    puts "TEST #{description}"
    steps.each {|step| step.execute(driver) }
  end
end

class AcceptanceTestRunner
  attr_reader :story
  attr_reader :test_description
  attr_reader :tests

  def initialize(file)
    @tests = []
    File.open(file) {|io| parse_stream(io) } unless file.nil?
  end
  
  def parse_string(string)
    require 'stringio'
    StringIO.open(string) {|io| parse_stream(io) }
  end
  
  def parse_stream(io)
    parse_story(io)
    parse_tests(io)
  end

  def parse_tests(io)
    while !io.eof?
      parse_test(io)
    end
  end
  
  def parse_test(io)
    test = nil
    io.each_line do |line|
      if line =~ /TEST: (.*)/
        test = AcceptanceTest.new($1)
        tests<<test
        break
      end
    end
    unless test.nil?
      step = nil
      multi_line_arg = nil
      io.each_line do |line|
        if !step.nil? && line =~ /^[\s]+(.*)$/
          if multi_line_arg.nil?
            multi_line_arg = ""
            step.args<<multi_line_arg
          else
            multi_line_arg<<"\n"
          end
          multi_line_arg<<$1.chomp(" ")
        else
          raise "format error" unless line =~ /^([^:]*)(:[\s]*)?(.*)$/
          task = $1 ; args = $3
          args = if args.nil? then [] else args.split(" ") end
          step = TestStep.new(task.chomp.chomp(" "), args)
          test.steps<<step
          multi_line_arg = nil
        end
      end
    end
  end
  
  def parse_story(io)
    @story = ""
    io.each_line do |line|
      if line =~ /^STORY: (.*)/
        @story = $1
      elsif line =~ /^$/
        break
      else
        @story<<"\n"
        @story<<line
      end
    end
    @story.chomp!
  end
  
  def driver
    @driver
  end
  
  def add_driver(driver)
    @driver = driver
  end
  
  def run
    puts "STORY #{story}"
    tests.each {|test| test.run(driver) }
    puts "=================="
  end
  
end

if $0 == __FILE__
  runner = AcceptanceTestRunner.new("../acceptance/codehaus_test.txt")
  runner.add_driver(TestDriver.new)
  runner.run
end