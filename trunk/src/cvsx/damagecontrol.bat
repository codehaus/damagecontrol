@ECHO OFF
REM This is a simple script that will trig damagecontrol via its socket interface.
REM The execution of this script is meant to be trigged by CVS when a commit occurs.
REM This script will only work on windows.
REM
REM In order to have CVS invoke this script upon a commit, add/commit it to the
REM project's CVSROOT folder. Then check out the CVSROOT/loginfo 
REM file, append the following line(*) to it and commit it.
REM
REM (*)
REM DEFAULT damagecontrol.bat name_of_the_project %{sVv}

ECHO "Calling into DamageControl"

ECHO BUILD %* | C:\cygwin\bin\nc localhost 4711
