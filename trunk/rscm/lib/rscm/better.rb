module RSCM
  class Better
    @@logger = nil
    @@logger = RSCM_DEFAULT_LOGGER
    
    def self.popen(cmd, mode="r", expected_exit=0, &proc)
      @@logger.info "Executing command: '#{cmd}'" if @@logger
      ret = IO.popen(cmd, mode) do |io|
        proc.call(io)
      end
      exit_code = $? >> 8
      raise "Command\n'#{cmd}'\nfailed with code #{exit_code} in\n#{Dir.pwd}\nExpected exit code: #{expected_exit}" if exit_code != expected_exit
      ret
    end
  end
end
