;NSIS Modern User Interface version 1.70
;Basic Example Script
;Written by Joost Verburg

;--------------------------------
;Include Modern UI

  !include "MUI.nsh"

;--------------------------------
;General

  !define ROOTDIR "..\..\.."
  !define DISTDIR "..\..\..\target\dist"
  
  ; VERSION needs to be defined on the command line with /DVERSION=1.2.3 option
  
  ;Name and file
  Name "DamageControl ${VERSION}"
  OutFile "${ROOTDIR}\target\DamageControl-${VERSION}.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\DamageControl"
  
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

Section "DamageControl Server" SecServer

  SetOutPath "$INSTDIR" 
  
  File "${DISTDIR}\license.txt"
  File /r "${DISTDIR}"
  
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
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\i386-mswin32
  File /r ${RUBY_HOME}\lib\ruby\1.8\i386-mswin32\*.so
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\i386-mswin32\digest
  File /r ${RUBY_HOME}\lib\ruby\1.8\i386-mswin32\digest\*.so
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\i386-mswin32\racc
  File /r ${RUBY_HOME}\lib\ruby\1.8\i386-mswin32\racc\*.so
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\webrick
  File /r ${RUBY_HOME}\lib\ruby\1.8\webrick\*.rb
  
  SetOutPath $INSTDIR\ruby\lib\ruby\1.8\webrick\httpservlet
  File /r ${RUBY_HOME}\lib\ruby\1.8\webrick\httpservlet\*.rb
    
  ;Include CVS binaries
;  SetOutPath $INSTDIR\cvs
;  File /r ${CVS_HOME}\cvs.exe
;  File /r ${CVS_HOME}\ext_protocol.dll
;  File /r ${CVS_HOME}\pserver_protocol.dll
  
  ;Store installation folder
  WriteRegStr HKCU "Software\Modern UI Test" "" $INSTDIR

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    
    ;Create shortcuts
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Start Server.lnk" "$INSTDIR\bin\server.cmd"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Stop Server.lnk" "$INSTDIR\bin\shutdownserver.cmd" "--url http://localhost:4712/private/xmlrpc"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Modify settings.lnk" "$WINDIR\notepad.exe" "$INSTDIR\bin\server.rb"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Dashboard.lnk" "http://localhost:4712/private/dashboard"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\DamageControl Website.lnk" "http://damagecontrol.codehaus.org"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  
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
  LangString DESC_SecServer ${LANG_ENGLISH} "The DamageControl server. Runs and monitors builds for multiple projects."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecServer} $(DESC_SecServer)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

Var STARTMENU_FOLDER_TEMP

Section "Uninstall"

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