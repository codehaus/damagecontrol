require 'damagecontrol/scm/AbstractTrackingConfigurator'
require 'damagecontrol/scm/Scarab'

module DamageControl
	class ScarabWebConfigurator < AbstractTrackingConfigurator
	
	public
	
		def tracking_class
			Scarab
		end
		
		def tracking_display_name
			"Scarab"
		end
		
		def config_form_template
      "scarab_configure_form.erb"
    end
		
	protected
	
		def configuration_keys
      [
        "scarab_url",
				"module_key"
      ]
    end
  end
end
