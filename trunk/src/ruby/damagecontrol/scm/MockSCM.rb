require 'ftools'
require 'damagecontrol/scm/SCM'

module DamageControl

    class MockSCM < SCM
    
        def handles_path?(path)
            # TODO: Should be debug
            puts "MockSCM.handles_path(#{path})"
            true
        end
        
        def checkout(path, directory, &proc)
            # TODO: Should be debug
            puts "MockSCM.checkout called"
        end
        
    end
end