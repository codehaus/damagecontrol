$:<<'../../lib'

require 'damagecontrol/Logging'
DamageControl::Logging.silent

require 'damagecontrol/scm/CVSTest'
require 'damagecontrol/scm/SVNTest'

require 'damagecontrol/BuildTest'
require 'damagecontrol/FilePollerTest'
require 'damagecontrol/AsyncComponentTest'
require 'damagecontrol/HubTest'
require 'damagecontrol/BuildDelayerTest'
require 'damagecontrol/TimerTest'
require 'damagecontrol/SlotTest'
require 'damagecontrol/LogWriterTest'
require 'damagecontrol/SocketTriggerTest'
require 'damagecontrol/XMLRPCTriggerTest'
require 'damagecontrol/SelfUpgraderTest'
require 'damagecontrol/BuildExecutorTest'
require 'damagecontrol/BuildSchedulerTest'
require 'damagecontrol/HostVerifyingHandlerTest'

require 'damagecontrol/publisher/IRCPublisherTest'
require 'damagecontrol/publisher/FilePublisherTest'
require 'damagecontrol/publisher/EmailPublisherTest'
require 'damagecontrol/BuildHistoryRepositoryTest'
require 'damagecontrol/publisher/XMLRPCStatusPublisherTest'
require 'damagecontrol/publisher/JabberPublisherTest'
require 'damagecontrol/publisher/JIRAPublisherTest'

require 'damagecontrol/template/HTMLTemplateTest'

#require 'damagecontrol/CVSPollerTest'
require 'damagecontrol/dependency/AllTraverserTest'
require 'damagecontrol/dependency/UpstreamDownstreamTraverserTest'

#require 'damagecontrol/CruiseControlBridgeTest'
require 'damagecontrol/cruisecontrol/CruiseControlLogPollerTest'
require 'damagecontrol/cruisecontrol/CruiseControlLogParserTest'

require 'IntegrationTests'

#require 'AcceptanceTestRunnerTest'
