@echo off
set DAMAGECONTROL_WORK=%~dp0

echo **************************************************
echo DamageControl's working files will be stored under
echo %DAMAGECONTROL_WORK%
echo This can be changed in 
echo %DAMAGECONTROL_WORK%\server.cmd
echo **************************************************

cd %DAMAGECONTROL_HOME%
set RUBY_HOME=%DAMAGECONTROL_HOME%\ruby
set PATH=%DAMAGECONTROL_HOME%\bin;%RUBY_HOME%\bin;%PATH%
set CMD=ruby -I "%DAMAGECONTROL_HOME%\server" "%~dp0server.rb" %1 %2 %3 %4 %5 %6 %7 %8 %9
echo %CMD%
%CMD%
pause
