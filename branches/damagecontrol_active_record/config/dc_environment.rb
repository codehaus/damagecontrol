DC_LIBS = ["lib", "../../trunk/rscm/lib", "../../trunk/rscm/test", "vendor/rscm/lib"]
$:.unshift(DC_LIBS.collect{|p| RAILS_ROOT+"/"+p}.join(':'))
# Require this file if it exists (it is generated by dist.rake)
require "#{RAILS_ROOT}/config/gems_environment" if File.exist?("#{RAILS_ROOT}/config/gems_environment.rb")
require 'damagecontrol'
