require 'damagecontrol/util/Logging'

DamageControl::Logging.silent

require 'damagecontrol/scm/CVSTest'
require 'damagecontrol/scm/SVNTest'

require 'damagecontrol/core/BuildTest'
require 'damagecontrol/util/FilePollerTest'
require 'damagecontrol/core/AsyncComponentTest'
require 'damagecontrol/core/HubTest'
require 'damagecontrol/util/TimerTest'
require 'damagecontrol/util/SlotTest'
require 'damagecontrol/core/LogWriterTest'
require 'damagecontrol/core/SocketTriggerTest'
require 'damagecontrol/xmlrpc/TriggerTest'
require 'damagecontrol/core/SelfUpgraderTest'
require 'damagecontrol/core/BuildExecutorTest'
require 'damagecontrol/core/BuildSchedulerTest'
require 'damagecontrol/core/HostVerifyingHandlerTest'

require 'damagecontrol/publisher/IRCPublisherTest'
require 'damagecontrol/publisher/EmailPublisherTest'
require 'damagecontrol/core/BuildHistoryRepositoryTest'
require 'damagecontrol/core/ProjectConfigRepositoryTest'
require 'damagecontrol/xmlrpc/StatusPublisherTest'
require 'damagecontrol/publisher/JabberPublisherTest'
require 'damagecontrol/publisher/JIRAPublisherTest'
require 'damagecontrol/web/ConfigureProjectTest'

require 'damagecontrol/template/HTMLTemplateTest'

require 'damagecontrol/dependency/AllTraverserTest'
require 'damagecontrol/dependency/UpstreamDownstreamTraverserTest'

require 'damagecontrol/cruisecontrol/CruiseControlLogPollerTest'
require 'damagecontrol/cruisecontrol/CruiseControlLogParserTest'

require 'damagecontrol/test/IntegrationTests'
