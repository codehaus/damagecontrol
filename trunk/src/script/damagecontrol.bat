@ECHO OFF
REM This is a simple script that will trig damagecontrol via its socket interface.
REM The execution of this script is meant to be trigged by the SCM when a commit occurs.
REM This script will only work on windows.
REM
REM In order to have CVS invoke this script upon a commit, add/commit it to the
REM project's CVSROOT folder. Then check out the CVSROOT/loginfo 
REM file, append the following line(*) to it and commit it.
REM
REM (*)
REM DEFAULT damagecontrol.bat name_of_the_project %{sVv}
REM
REM You should also make sure that nc.exe is on the path
REM
REM %~dp0 is magic for "folder of current script + a backslash"

ECHO BUILD %* | %~dp0nc.exe localhost 4711
