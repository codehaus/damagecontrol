;NSIS Modern User Interface version 1.70
;Basic Example Script
;Written by Joost Verburg

;--------------------------------
;Include Modern UI

  !include "MUI.nsh"

;--------------------------------
;General

  !define ROOTDIR "..\..\.."
  !define DISTDIR "${ROOTDIR}\target\dist"
  
  ; VERSION needs to be defined on the command line with /DVERSION=1.2.3 option
  ; RUBY_HOME needs to point to a Cygwin Ruby distribution built from source. 
  ; 
  ; CVS_EXECUTABLE needs to point to a NON-CYGWIN CVS executable.
  
  ;Name and file
  Name "DamageControl ${VERSION}"
  !define DISTNAME "DamageControl-${VERSION}"
  OutFile "${ROOTDIR}\target\${DISTNAME}.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\${DISTNAME}"
  
  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\DamageControl" ""

;--------------------------------
;Variables

  Var STARTMENU_FOLDER

;--------------------------------
;Interface Settings

  !define MUI_HEADERIMAGE
  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "${DISTDIR}\license.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  
  ;Start Menu Folder Page Configuration
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
  !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\DamageControl" 
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
  
  !insertmacro MUI_PAGE_STARTMENU Application $STARTMENU_FOLDER

  !insertmacro MUI_PAGE_INSTFILES
  
  Page custom PostInstallInstructionsPage
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Reserve Files
  
  ;These files should be inserted before other files in the data block
  ;Keep these lines before any File command
  ;Only for solid compression (by default, solid compression is enabled for BZIP2 and LZMA)
  
  ReserveFile "PostInstallInstructions.ini"
  !insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
  
;--------------------------------
;Installer Sections

Section "" ; empty string makes it hidden, so would starting with -

  
  ; Set the DAMAGECONTROL_HOME and DAMAGECONTROL_WORK environment variables
  WriteRegStr HKLM "SYSTEM\ControlSet001\Control\Session Manager\Environment" "DAMAGECONTROL_HOME" "$INSTDIR"
  WriteRegStr HKLM "SYSTEM\ControlSet001\Control\Session Manager\Environment" "DAMAGECONTROL_WORK" "$PROFILE\.damagecontrol"

  ;Create uninstaller
  SetOutPath "$INSTDIR" 
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Register uninstaller in registry
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DISTNAME}" "DisplayName" "DamageControl ${VERSION} (remove only)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DISTNAME}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DISTNAME}" "Publisher" "Codehaus"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DISTNAME}" "HelpLink" "user@damagecontrol.codehaus.org"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DISTNAME}" "URLInfoAbout" "http://damagecontrol.codehaus.org"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DISTNAME}" "URLUpdateInfo" "http://damagecontrol.codehaus.org"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DISTNAME}" "Readme" "$INSTDIR\release-notes.txt"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DISTNAME}" "Contact" "irc:irc.codehaus.org#damagecontrol"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DISTNAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DISTNAME}" "NoRepair" 1

SectionEnd

Section "Working Directory" SecWork
  
  SetOutPath $PROFILE\.damagecontrol
  File ${ROOTDIR}\bin\damagecontrol.cmd
  File ${ROOTDIR}\bin\server.rb
  
  ;Include a default log configuration
  File "${ROOTDIR}\installer\windows\nsis\log4r.xml"

SectionEnd

Section "DamageControl Server" SecServer

  ;Include CVS binaries
  SetOutPath $INSTDIR\bin
  File /r "${CVS_EXECUTABLE}"

  SetOutPath "$INSTDIR" 
  File "${DISTDIR}\license.txt"
  File "${DISTDIR}\release-notes.txt"
  File /r "${DISTDIR}\*"

  ;Include extra Windows cygwin binaries
  SetOutPath $INSTDIR\bin
  File /r "${ROOTDIR}\installer\windows\bin\*"
  
  ;Include 
    
  ;Store installation folder
  WriteRegStr HKCU "Software\Modern UI Test" "" $INSTDIR

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Start DamageControl Server.lnk" "$PROFILE\.damagecontrol\damagecontrol.cmd" "$PROFILE\.damagecontrol\server.rb" "$INSTDIR\server\damagecontrol\web\icons\ico\damagecontrol-icon-square.ico"
    ;CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Stop DamageControl Server.lnk" "$PROFILE\.damagecontrol\damagecontrol.cmd" "%DAMAGECONTROL_HOME%\bin\shutdownserver.rb --url http://localhost:4712/private/xmlrpc"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Modify DamageControl settings.lnk" "$WINDIR\notepad.exe" "$PROFILE\.damagecontrol\server.rb"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\DamageControl Dashboard.lnk" "http://localhost:4712/private/dashboard"  "$INSTDIR\server\damagecontrol\web\icons\ico\damagecontrol-icon-square.ico"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\DamageControl Website.lnk" "http://damagecontrol.codehaus.org"  "$INSTDIR\server\damagecontrol\web\icons\ico\damagecontrol-icon-square.ico"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall DamageControl.lnk" "$INSTDIR\Uninstall.exe"
  
  !insertmacro MUI_STARTMENU_WRITE_END

SectionEnd

Section "Ruby" SecRuby
  ;Include a minimal ruby installation (to reduce the size of the installer)

  SetOutPath $INSTDIR\ruby\bin
  File /r ${RUBY_HOME}\bin\*.exe
  File /r ${RUBY_HOME}\bin\*.dll

  SetOutPath $INSTDIR\ruby\lib\ruby\1.8
  File /r ${RUBY_HOME}\lib\ruby\1.8\*.rb
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\date
  File /r ${RUBY_HOME}\lib\ruby\1.8\date\*.rb
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\net
  File /r ${RUBY_HOME}\lib\ruby\1.8\net\*.rb
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\i386-cygwin
  File /r ${RUBY_HOME}\lib\ruby\1.8\i386-cygwin\*.so
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\i386-cygwin\digest
  File /r ${RUBY_HOME}\lib\ruby\1.8\i386-cygwin\digest\*.so
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\i386-cygwin\racc
  File /r ${RUBY_HOME}\lib\ruby\1.8\i386-cygwin\racc\*.so
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\webrick
  File /r ${RUBY_HOME}\lib\ruby\1.8\webrick\*.rb
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\webrick\httpservlet
  File /r ${RUBY_HOME}\lib\ruby\1.8\webrick\httpservlet\*.rb
    
SectionEnd

Section "DCTray.NET" SecDCTray
  SetOutPath "$INSTDIR\DCTray.NET"
  File ${ROOTDIR}\client\DotNet\WindowsTray\bin\Release\DCWindowsTray.exe
  File ${ROOTDIR}\client\DotNet\WindowsTray\bin\Release\DamageControlClientNet.dll
  File ${ROOTDIR}\client\DotNet\WindowsTray\bin\Release\XmlRpcCs.dll
  File ${ROOTDIR}\client\DotNet\WindowsTray\bin\Release\extremely_well.wav
  File ${ROOTDIR}\client\DotNet\WindowsTray\bin\Release\fault.wav
  File ${ROOTDIR}\client\DotNet\WindowsTray\bin\Release\feeling_better.wav
  File ${ROOTDIR}\client\DotNet\WindowsTray\bin\Release\human_error.wav
  
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
  
    SetShellVarContext all ; (Add to "All Users" Start Menu if possible)
    
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\DCTray.NET Systray Monitor.lnk" "$INSTDIR\DCTray.NET\DCWindowsTray.exe"
    
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

;--------------------------------
;Installer Functions

Function .onInit

  ;Extract InstallOptions INI files
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "PostInstallInstructions.ini"
  
FunctionEnd

LangString TEXT_IO_TITLE ${LANG_ENGLISH} "Post-install instructions"
LangString TEXT_IO_SUBTITLE ${LANG_ENGLISH} "Getting started with DamageControl."

Function PostInstallInstructionsPage

  !insertmacro MUI_HEADER_TEXT "$(TEXT_IO_TITLE)" "$(TEXT_IO_SUBTITLE)"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "PostInstallInstructions.ini"

FunctionEnd

;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_SecWork ${LANG_ENGLISH} "(WARNING! Don't select this if you are upgrading). The DamageControl startup scripts. Will be installed in .damagecontrol under your home directory."
  LangString DESC_SecServer ${LANG_ENGLISH} "The DamageControl server. Runs and monitors builds for multiple projects."
  LangString DESC_SecDCTray ${LANG_ENGLISH} "DamageControl systray monitor. Require Microsoft .NET Framework 1.1. The systray can be installed separately, doesn't require the server or a Ruby distribution."
  LangString DESC_SecRuby ${LANG_ENGLISH} "Ruby distribution tuned for DamageControl. It is recommended to use this Ruby distribution unless you really know what you are doing. DamageControl requires a Cygwin build of Ruby (it has to support fork)."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecWork} $(DESC_SecWork)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecServer} $(DESC_SecServer)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDCTray} $(DESC_SecDCTray)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecRuby} $(DESC_SecRuby)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

Var STARTMENU_FOLDER_TEMP

Section "Uninstall"
  SetShellVarContext all ; (Also delete from "All Users" Start Menu if possible)

  Delete "$INSTDIR\Uninstall.exe"

  RMDir /r "$INSTDIR"

  !insertmacro MUI_STARTMENU_GETFOLDER Application $STARTMENU_FOLDER_TEMP
    
  RMDir /r "$SMPROGRAMS\$STARTMENU_FOLDER_TEMP"
  
  ;Delete empty start menu parent diretories
  StrCpy $STARTMENU_FOLDER_TEMP "$SMPROGRAMS\$STARTMENU_FOLDER_TEMP"
 
  startMenuDeleteLoop:
    RMDir $STARTMENU_FOLDER_TEMP
    GetFullPathName $STARTMENU_FOLDER_TEMP "$STARTMENU_FOLDER_TEMP\.."
    
    IfErrors startMenuDeleteLoopDone
  
    StrCmp $STARTMENU_FOLDER_TEMP $SMPROGRAMS startMenuDeleteLoopDone startMenuDeleteLoop
  startMenuDeleteLoopDone:

  DeleteRegKey /ifempty HKCU "Software\DamageControl"

SectionEnd