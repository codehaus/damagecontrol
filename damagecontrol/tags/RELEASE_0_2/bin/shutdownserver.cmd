@echo off
set DAMAGECONTROL_HOME=%~dp0..
cd %DAMAGECONTROL_HOME%
set RUBY_HOME="%DAMAGECONTROL_HOME%\ruby"
set PATH="%DAMAGECONTROL_HOME%\ruby\bin";%PATH%
ruby -I"%DAMAGECONTROL_HOME%\server" "%DAMAGECONTROL_HOME%\bin\shutdownserver.rb" --url %1
