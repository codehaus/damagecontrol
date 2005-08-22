raise 'load environment.rb instead of dc_environment.rb' unless defined?(RAILS_ENV)

LIBS = ["lib", "../../trunk/rscm/lib", "../../trunk/rscm/test"]
$:.unshift(LIBS.join(':'))
require 'rscm'

unless defined? DAMAGECONTROL_HOME
  if(['test', 'development'].include?(RAILS_ENV))
    # DAMAGECONTROL_HOME goes into target for these environments.
    DAMAGECONTROL_HOME = File.expand_path(__FILE__ + "/../../target/#{RAILS_ENV}")
  elsif(ENV['DAMAGECONTROL_HOME'])
    DAMAGECONTROL_HOME = ENV['DAMAGECONTROL_HOME']
  else
    if(WINDOWS)
      DAMAGECONTROL_HOME = 
        RSCM::PathConverter.nativepath_to_filepath("#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}/.damagecontrol").gsub(/\\/, "/")
    else
      DAMAGECONTROL_HOME = 
        "#{ENV['HOME']}/.damagecontrol"
    end
  end
end
require 'damagecontrol'

class ActiveRecord::ConnectionAdapters::AbstractAdapter
  # Expose connection. We need to set the busy_handler
  attr_reader :connection
end

# Make SQLite retry if the database is busy.
#sqlite = ActiveRecord::Base.connection.connection
#sqlite.busy_timeout(5000)
#sqlite.busy_handler do |resource, retries|
#  $stderr.puts "Busy: #{resource}, #{retries}"
#  true
#end
