require 'ftools'
require 'rubygems'
require_gem 'rscm'

module DamageControl
  
  class NoSCM < ::RSCM::AbstractSCM
    def name
      "NoSCM"
    end

    def method_missing(*args)
      "NoSCM does nothing :-)"
      self
    end
    
    def checkout(checkout_dir, time = nil, &proc)
      File.mkpath(checkout_dir)
      nil
    end
  end
end