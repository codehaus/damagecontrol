$:<<'../../lib'

require 'damagecontrol/CruiseControlBridge'

include DamageControl

bridge = CruiseControlBridge.new
bridge.jars<<"starteam-sdk.jar"
bridge.sourcecontrol = "net.sourceforge.cruisecontrol.sourcecontrols.StarTeam"
bridge.parameters["folder"] = "Development"
bridge.parameters["starteamurl"] = "starteam://brian:49201/Eclipse Release 3/Eclipse Release 3"
bridge.parameters["username"] = "jtirsen"
bridge.parameters["password"] = "jtirsen"
print bridge.modifications(Time.now - 1000000, Time.now)
