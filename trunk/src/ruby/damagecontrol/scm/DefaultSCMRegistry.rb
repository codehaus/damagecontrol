require 'damagecontrol/scm/SCMRegistry'
require 'damagecontrol/scm/SVN'
require 'damagecontrol/scm/CVS'

module DamageControl
    class DefaultSCMRegistry < SCMRegistry
        def initialize
            super
            add_scm(CVS.new)
            add_scm(SVN.new)
        end
    end
end