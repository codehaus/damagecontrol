@echo off
set DAMAGECONTROL_HOME=%~dp0..
cd %DAMAGECONTROL_HOME%
set RUBY_HOME="%DAMAGECONTROL_HOME%\ruby"
set RUBY_HOME=C:\cygwin\bin
set PATH="%RUBY_HOME%\bin";%PATH%
ruby -I"%DAMAGECONTROL_HOME%\server" "%DAMAGECONTROL_HOME%\server\damagecontrol\tool\admin\requestbuild.rb" %1 %2 %3 %4 %5 %6 %7 %8 %9  
    
