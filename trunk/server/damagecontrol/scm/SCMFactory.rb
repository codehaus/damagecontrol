require 'damagecontrol/scm/CVS'
require 'damagecontrol/scm/SVN'
require 'damagecontrol/scm/NoSCM'
require 'damagecontrol/util/Logging'

module DamageControl
  class SCMFactory
    include Logging
  
    # these are preconfigured "shortcuts", if you want to use another class as your scm just specify the full classname in your config file
    PRECONFIGURED_SCM_CLASSES = {
      "" => DamageControl::NoSCM,
      nil => DamageControl::NoSCM,
      "cvs" => DamageControl::CVS,
      "svn" => DamageControl::SVN
    }
    
    def get_scm(config_map, checkout_dir)
      config_map = config_map.dup
      config_map["checkout_dir"] = checkout_dir
      
      scm_class = scm_class_name(config_map["scm_type"])
      scm_class.new(config_map)
    end
    
    def scm_class_name(scm_type)
      scm_class = PRECONFIGURED_SCM_CLASSES[scm_type]
      begin
        scm_class = eval(scm_type) if scm_class.nil?
      rescue Exception => e
        logger.error("could not find scm class: #{scm_type}")
      end
      
      scm_class
    end
  end
end
