# :nodoc:

require 'log4r/outputter/outputter'
require 'log4r/staticlogger'
require 'net/smtp'

module Log4r

  # = EmailOutputter
  # 
  # This is an experimental class. It should work fine if Net:SMTP doesn't
  # give you any problems. Just in case, create a logger named 'log4r'
  # and give it an outputter to see the logging statements made by
  # this class. If it fails to send email, it will set itself to OFF
  # and stop logging.
  #
  # In order to use it,
  #
  #   require 'log4r/outputter/emailoutputter'
  #
  # == SMTP Configuration
  #
  # All arguments to Net::SMTP.start are supported. Pass them as hash
  # parameters to +new+. The to field is specified as a comma-delimited 
  # list of emails (padded with \s* if desired).
  #
  # An example:
  # 
  #   EmailOutputter.new 'myemail',
  #                      :server=>'localhost',
  #                      :port=>25,
  #                      :domain=>'somewhere.com',
  #                      :from=>'me@foo.bar',
  #                      :to=>'them@foo.bar, me@foo.bar, bozo@clown.net'
  #
  # == LogEvent Buffer
  #
  # This class has an internal LogEvent buffer to let you accumulate a bunch
  # of log messages per email. Specify the size of the buffer with the
  # hash parameter +buffsize+. The default is 100.
  # 
  # == Flush Me
  #
  # When shutting down your program, you might want to call flush
  # on this outputter to send the remaining LogEvents. Might as well
  # flush everything while you're at it:
  # 
  #   Outputter.each_outputter {|o| o.flush}
  #
  # == Format When?
  #
  # You may choose to format the LogEvents as they come in or as the
  # email is being composed. To do the former, specify a value of +true+
  # to the hash parameter +formatfirst+. The default is to format 
  # during email composition.
  #
  # == Immediate Notification
  #
  # If you want certain log priorities to trigger an immediate email,
  # set the hash parameter +immediate_at+ to a string list of comma-delimited
  # trigger levels (padded by \s* if desired).
  #
  # == Example
  #
  # A security logger sends email to several folks, buffering up to 25
  # log events and sending immediates on CRIT and WARN
  #
  #   EmailOutputter.new 'security', 
  #                      :to => 'bob@secure.net, frank@secure.net',
  #                      :buffsize => 25,
  #                      :immediate_at => 'WARN, CRIT'
  #                      
  # == XML Configuration
  #
  # See log4r/configurator.rb for details. Here's an example:
  #
  #   <outputter name="security" type="EmailOutputter"
  #              buffsize="25" level="ALL">
  #     <immediate_at>WARN, CRIT</immediate_at>
  #     <server>localhost</server>
  #     <from>me@secure.net</from>
  #     <to>
  #       bob@secure.net, frank@secure.net
  #     </to>
  #     ...
  #   </outputter>

  class EmailOutputter < Outputter
    attr_reader :server, :port, :domain, :acct, :authtype

    def initialize(_name, hash={})
      super(_name, hash)
      validate(hash)
      @buff = []
      begin 
        @smtp = Net::SMTP.start(*@params)
        Logger.log_internal {
          "EmailOutputter '#{@name}' running SMTP client on #{@server}:#{@port}"
        }
      rescue Exception => e
        Logger.log_internal (-2) {
          "EmailOutputter '#{@name}' failed to start SMTP client!"
        }
        Logger.log_internal {e}
        self.level = OFF
      end
    end

    # send out an email with the current buffer
    def flush
      synch { send_mail }
      Logger.log_internal {"Flushed EmailOutputter '#{@name}'"}
    end

    private

    def validate(hash)
      @buffsize = (hash[:buffsize] or hash['buffsize'] or 100).to_i
      @formatfirst = Log4rTools.decode_bool(hash, :formatfirst, false)
      decode_immediate_at(hash)
      validate_smtp_params(hash)
    end

    def decode_immediate_at(hash)
      @immediate = Hash.new
      _at = (hash[:immediate_at] or hash['immediate_at'])
      return if _at.nil?
      Log4rTools.comma_split(_at).each {|lname|
        level = LNAMES.index(lname)
        if level.nil?
          Logger.log_internal(-2) do
            "EmailOutputter: skipping bad immediate_at level name '#{lname}'"
          end
          next
        end
        @immediate[level] = true
      }
    end

    def validate_smtp_params(hash)
      @from = (hash[:from] or hash['from'])
      raise ArgumentError, "Must specify from address" if @from.nil?
      _to = (hash[:to] or hash['to'] or "")
      @to = Log4rTools.comma_split(_to) 
      raise ArgumentError, "Must specify recepients" if @to.empty?
      @server = (hash[:server] or hash['server'] or 'localhost')
      @port = (hash[:port] or hash['port'] or 25).to_i
      @domain = (hash[:domain] or hash['domain'] or ENV['HOSTNAME'])
      @acct = (hash[:acct] or hash['acct'])
      @passwd = (hash[:passwd] or hash['passwd'])
      @authtype = (hash[:authtype] or hash['authtype'] or :cram_md5).to_s.intern
      @params = [@server, @port, @domain, @acct, @passwd, @authtype]
    end

    def canonical_log(event)
      synch {
        @buff.push case @formatfirst
          when true then @formatter.format event
          else event 
          end
        send_mail if @buff.size >= @buffsize or @immediate[event.level]
      }
    end

    def send_mail
      msg = 
        case @formatfirst
        when true then @buff.join 
        else @buff.collect{|e| @formatter.format e}.join 
        end
      begin @smtp.sendmail(msg, @from, @to)
      rescue Exception => e
        Logger.log_internal(-2) {
          "EmailOutputter '#{@name}' couldn't send email!"
        }
        Logger.log_internal {e}
        self.level = OFF
      ensure @buff.clear
      end
    end
  end
end
