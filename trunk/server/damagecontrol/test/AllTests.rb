require 'damagecontrol/util/Logging'

DamageControl::Logging.silent

###### Keep it alphabetical - easier to keep track then ######

require 'damagecontrol/core/BuildExecutorTest'
require 'damagecontrol/core/BuildHistoryRepositoryTest'
require 'damagecontrol/core/BuildSchedulerTest'
require 'damagecontrol/core/BuildTest'
require 'damagecontrol/core/CheckoutManagerTest'
require 'damagecontrol/core/DependentBuildTriggerTest'
#require 'damagecontrol/core/EqualityTest'
require 'damagecontrol/core/HostVerifyingHandlerTest'
require 'damagecontrol/core/LogWriterTest'
require 'damagecontrol/core/LogMergerTest'
require 'damagecontrol/core/ArtifactArchiverTest'
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
require 'damagecontrol/util/FileUtilsTest'
require 'damagecontrol/util/XMLMergerTest'

require 'damagecontrol/xmlrpc/StatusPublisherTest'
require 'damagecontrol/xmlrpc/TriggerTest'

require 'damagecontrol/web/ConfigureProjectTest'
require 'damagecontrol/web/ConfigureProjectServletTest'
require 'damagecontrol/web/InstallTriggerServletTest'
require 'damagecontrol/web/ProjectServletTest'
require 'damagecontrol/web/ChangesReportTest'
require 'damagecontrol/web/SearchServletTest'
require 'damagecontrol/web/ProjectStatusTest'
require 'damagecontrol/web/BuildExecutorStatusTest'

# let's stick to unit test and e2etest
#require 'damagecontrol/test/IntegrationTests'

#!
require 'pebbles/ClockTest'
require 'pebbles/LineEditorTest'
require 'pebbles/MatchableTest'
require 'pebbles/PathutilsTest'
require 'pebbles/ParserTest'
require 'pebbles/ProcessTest'
require 'pebbles/RiteMeshTest'
require 'pebbles/TimeUtilsTest'
