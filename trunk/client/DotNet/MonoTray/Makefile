install-gconf-schema:
	GCONF_CONFIG_SOURCE="" gconftool-2 --makefile-install-rule monotray.schema
	

Settings.cs: monotray.schema
	gconfsharp-schemagen ThoughtWorks.DamageControl.MonoTray monotray.schema > Settings.cs
