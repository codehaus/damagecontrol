require 'damagecontrol/util/Logging'

DamageControl::Logging.silent

require 'damagecontrol/core/AsyncComponentTest'
require 'damagecontrol/core/BuildExecutorTest'
require 'damagecontrol/core/BuildHistoryRepositoryTest'
require 'damagecontrol/core/BuildSchedulerTest'
require 'damagecontrol/core/BuildTest'
#require 'damagecontrol/core/EqualityTest'
require 'damagecontrol/core/HostVerifyingHandlerTest'
require 'damagecontrol/core/HubTest'
require 'damagecontrol/core/LogWriterTest'
require 'damagecontrol/core/ProjectConfigRepositoryTest'
require 'damagecontrol/core/ProjectDirectoriesTest'
require 'damagecontrol/core/SCMPollerTest'

require 'damagecontrol/cruisecontrol/CruiseControlLogPollerTest'
require 'damagecontrol/cruisecontrol/CruiseControlLogParserTest'

require 'damagecontrol/dependency/AllTraverserTest'
require 'damagecontrol/dependency/UpstreamDownstreamTraverserTest'

require 'damagecontrol/publisher/EmailPublisherTest'
require 'damagecontrol/publisher/IRCPublisherTest'
require 'damagecontrol/publisher/JabberPublisherTest'
require 'damagecontrol/publisher/JIRAPublisherTest'

require 'damagecontrol/scm/ChangesTest'
require 'damagecontrol/scm/CVSTest'
require 'damagecontrol/scm/CVSLogParserTest'
require 'damagecontrol/scm/SVNTest'
require 'damagecontrol/scm/SVNLogParserTest'

require 'damagecontrol/util/FilePollerTest'
require 'damagecontrol/util/SlotTest'
require 'damagecontrol/util/TimerTest'

require 'damagecontrol/xmlrpc/StatusPublisherTest'
require 'damagecontrol/xmlrpc/TriggerTest'

require 'damagecontrol/web/ConfigureProjectTest'
require 'damagecontrol/web/InstallTriggerServletTest'

require 'damagecontrol/test/IntegrationTests'

require 'pebbles/RiteMeshTest'
require 'pebbles/TimeUtilsTest'
require 'pebbles/MatchableTest'
