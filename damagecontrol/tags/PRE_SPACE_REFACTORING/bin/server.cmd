@echo off
set DAMAGECONTROL_HOME=%~dp0..
cd %DAMAGECONTROL_HOME%
set CYGWIN_HOME="%DAMAGECONTROL_HOME%\cygwin"
set PATH="%CYGWIN_HOME%\bin";%PATH%
bash -c "/bin/ruby -I server bin/server.rb"
pause