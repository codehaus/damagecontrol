module RSCM
  # Utility for running a +cmd+ in a +dir+ with a specified +env+.
  # If a block is passed, the standard out stream is passed to that block (and returns)
  # the result from the block. Otherwise, if a block is not passed, standard output
  # is redirected to +stdout_file+. The standard error stream is always redirected
  # to +stderr_file+. Note that both +stdout_file+ and +stderr_file+ must always
  # be specified with non-nil values, as both of them will always have the command lines
  # written to them.
  module CommandLine
    class OptionError < StandardError; end
    class ExecutionError < StandardError
      attr_reader :cmd, :dir, :exitstatus, :stderr      
      def initialize(cmd, dir, exitstatus, stderr); @cmd, @dir, @exitstatus, @stderr = cmd, dir, exitstatus, stderr; end
      def to_s
        "\ndir       : #{@dir}\n" +
        "command   : #{@cmd}\n" +
        "exitstatus: #{@exitstatus}\n" +
        "stderr    : #{@stderr}\n"
      end
    end
    
    def execute(cmd, options={}, &proc)
      options = {
        :dir => Dir.pwd,
        :env => {},
        :exitstatus => 0
      }.merge(options)
      
      raise OptionError.new(":stdout can't be nil") if options[:stdout].nil?
      raise OptionError.new(":stderr can't be nil") if options[:stderr].nil?
      options[:stdout] = File.expand_path(options[:stdout])
      options[:stderr] = File.expand_path(options[:stderr])

      commands = cmd.split("&&").collect{|c| c.strip}
      Dir.chdir(options[:dir]) do
        redirected_cmd = commands.collect do |c|
          redirection = block_given? ? "#{c} 2>> #{options[:stderr]}" : "#{c} >> #{options[:stdout]} 2>> #{options[:stderr]}"

          "echo #{RSCM::Platform.prompt} #{c} >> #{options[:stdout]} && " +
          "echo #{RSCM::Platform.prompt} #{c} >> #{options[:stderr]} && " +
          redirection
        end.join(" && ")

        options[:env].each{|k,v| ENV[k]=v}
        begin
          IO.popen(redirected_cmd) do |io|
            if(block_given?)
              return(proc.call(io))
            else
              io.read
            end
          end
        rescue Errno::ENOENT => e
          File.open(options[:stderr], "a") {|io| io.write(e.message)}
        ensure
          if($?.exitstatus != options[:exitstatus])
            error_message = File.exist?(options[:stderr]) ? File.read(options[:stderr]) : "#{options[:stderr]} doesn't exist"
            raise ExecutionError.new(cmd, options[:dir], $?.exitstatus, error_message)
          end
        end
      end
      $?.exitstatus
    end
    module_function :execute
  end
end