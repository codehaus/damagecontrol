raise 'load environment.rb instead of dc_environment.rb' unless defined?(RAILS_ENV)

LIBS = []#["lib", "../../trunk/rscm/lib", "../../trunk/rscm/test", "vendor/rscm/lib"]
$:.unshift(LIBS.collect{|p| RAILS_ROOT+"/"+p}.join(':'))
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
