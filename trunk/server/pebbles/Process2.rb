require 'timeout'

module Pebbles   

  at_exit do
    ObjectSpace.each_object(Pebbles::Win32Process) do |p|
      p.kill if p.running?
    end
  end

  at_exit do
    ObjectSpace.each_object(Pebbles::PosixProcess) do |p|
      p.kill if p.running?
    end
  end

  class Process2

    def initialize(cmd, stderr_file=nil, env={}, timeout=nil)
      @cmd, @stderr_file, @env, @timeout = cmd, stderr_file, env, timeout
      @cmd2 = stderr_file ? "#{@cmd} 2> \"#{@stderr_file}\"" : @cmd
      
      niceness = ENV['DC_NICE']
      @cmd2 = "nice --adjustment=#{niceness} #{@cmd2}" if niceness
    end
    
    def execute(&proc)
      win32? ? execute_win32(&proc) : execute_posix(&proc)
    end
    
  private
  
    def Process2.win32_processes
      processes = []
      IO.popen("tasklist") do |stdout|
        stdout.each do |line|
          if(line =~ /(.+)\s+([0-9]+) [a-zA-Z]+\s+[0-9]+\s+/)
            image = $1.strip
            pid = $2.to_i
            processes << Win32Process.new(pid, image)
          end
        end
      end
      processes
    end
    
    def win32?
      RUBY_PLATFORM == "i386-mswin32"
    end

    def execute_posix(&prco)
      process = nil
      timeout(@timeout) do
        begin
          pr = IO::pipe

          pid = fork do
            pr[0].close
            STDOUT.reopen(pr[1])
            pr[1].close

            @env.each {|key, val| ENV[key] = val}
            exec(@cmd2)
          end
          pr[1].close
          process = PosixProcess.new(pid)
          yield [pr[0], process] if block_given?
          pid, ret = Process.waitpid2(pid)
          ret.exitstatus

        rescue Timeout::Error
          process.kill
          nil
        ensure
          process.running = false if process
        end
      end
    end

    def execute_win32(&proc)
      processes_before = Process2.win32_processes
      process = nil
      timeout(@timeout) do
        begin
          @env.each {|key, val| ENV[key] = val}
          IO.popen(@cmd2) do |stdout|
            processes_after = Process2.win32_processes
            new_processes = processes_after - processes_before
            regexp = /#{@cmd}/
            process = new_processes.find do |p| 
              p.image =~ regexp
            end
            process.running = true if process
            yield stdout, process if block_given?
          end
          if(@stderr_file)
            File.open(@stderr_file) do |f|
              return 127 if f.read =~ /is not recognized as an internal or external command/
            end
          end
          process && process.killed? ? nil : $?.to_i / 256
        rescue Errno::ENOENT
          1
        rescue Timeout::Error
          process.kill
          nil
        ensure
          process.running = false if process
        end
      end
    end

  end

  class PosixProcess
    @@instances = []
    attr_writer :running

    def initialize(pid)
      @pid = pid
      @running = true
      @killed = false
      @@instances << self
    end
    
    def kill
      begin
        Process.kill(9, @pid)
        @killed = true
        @running = false
      rescue
      end
    end

    def killed?
      @killed
    end

    def running?
      @running
    end
  end
  
  class Win32Process
    @@instances = []
  
    attr_reader :pid, :image
    attr_writer :running
  
    def initialize(pid, image)
      @pid, @image = pid, image
      @running = false
      @killed = false
      @@instances << self
    end
    
    def ==(p)
      pid = p.pid && image == p.image
    end
    
    def eql?(p)
      self == p
    end

    def hash
      pid
    end

    def kill
      cmd = "taskkill /PID #{pid}"
      begin
        IO.popen(cmd) do |stdout|
          result = stdout.read
          raise result unless result =~ /SUCCESS/
        end
        @killed = true
        @running = false
      rescue
      end
    end
    
    def killed?
      @killed
    end
    
    def running?
      @running
    end
    
    def to_s
      "#{pid} #{image}"
    end
  end
end
