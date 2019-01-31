@ECHO OFF
ECHO OFF
CLS

REM ###########################################################################################################

   REM ### Create new Variable Namespace ###
   SETLOCAL ENABLEDELAYEDEXPANSION

   REM ### Initialize Script Workspace ###
   SET SOURCEPATH=%~dp0
   IF /I "%SOURCEPATH:~-1%"=="\" SET SOURCEPATH=%SOURCEPATH:~0,-1%
   PUSHD "%SOURCEPATH%" >NUL 2>&1
   FOR /F "tokens=* delims=" %%A IN ('CD') DO (SET WORKINGDIR=%%A)
   IF /I "%WORKINGDIR:~-1%"=="\" SET WORKINGDIR=%WORKINGDIR:~0,-1%

   REM ### Initialize Error Handling Variables ###
   SET ERRORCODE=0
   SET ERRORMODULE=MAIN
   SET ERRORSOURCE=
   SET ERROROUTPUT=%TEMP%\ERROROUTPUT.TMP
   SET ERRORHANDLER=^>"^!ERROROUTPUT^!" 2^>^&1
   SET LF=^


   REM ### Keep Line-Feeds above for Error Handling ###
   DEL /A /F /Q "%ERROROUTPUT%" >NUL 2>&1
   VERIFY >NUL

   REM ### Initialize and Configure Code Page Settings ###
   FOR /F "tokens=2 delims=.:" %%A IN ('CHCP') DO (SET "CODEPAGE=%%A" & SET "CODEPAGE=!CODEPAGE: =!")
   CHCP 1252 %ERRORHANDLER%
   IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=CHCP" & GOTO ERROR)

   REM ### Configure Version and Script Titles ###
   SET VERSION=v1.2 by SoftSonic83
   SET TITLE=APPX-DB Modification Script %VERSION%
   TITLE %TITLE% %ERRORHANDLER%
   IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=TITLE" & GOTO ERROR)

REM ###########################################################################################################

   REM ### Detect Operating System Bitness ###
   SET BITNESS=x64
   IF %PROCESSOR_ARCHITECTURE%==x86 (
      IF NOT DEFINED PROCESSOR_ARCHITEW6432 (
         SET BITNESS=x86
      )
   )

   REM ### Define Paths for Tools and Functions ###
   SET FART=%WORKINGDIR%\Tools\FART\%BITNESS%\FART.EXE
   SET NIRCMD=%SOURCEPATH%\Tools\NIRCMD\%BITNESS%\NIRCMD.EXE
   SET SQLITE=%SOURCEPATH%\Tools\SQLITE\SQLITE.EXE

   REM ### Define Macros for Function Calls ###
   SET RUNASSYSTEM="%NIRCMD%" ELEVATECMD RUNASSYSTEM "%NIRCMD%" EXEC HIDE CMD /C
   SET CMDSYNCWAIT=START "" /B /WAIT "%NIRCMD%" WAIT

REM ###########################################################################################################

   REM ### Define Script Behavior Parameters ###
   SET SCRIPT_IGNOREMISSINGPKG=TRUE

   REM ### Initialize additional Script Variables ###
   SET BREAK_A=
   SET BREAK_B=
   SET OPERATION=
   SET RUNMODE=NORMAL
   SET /A STEPINDEX=0
   SET /A SUBSTEPINDEX=0

   REM ### Define Appx-DB related Paths and Script Constants ###
   SET APPX_DATABASEPATH=%ProgramData%\Microsoft\Windows\AppRepository\StateRepository-Machine.srd
   SET APPX_DATABASEPATH_NEW=
   SET APPX_PACKAGELIST=%WORKINGDIR%\AppxPackageList.txt
   SET APPX_PACKAGELIST_NEW=
   SET APPX_PACKAGEDUMP=%WORKINGDIR%\AppxPackageDump.txt
   SET APPX_PACKAGEDUMP_TEMP=%TEMP%\AppxPackageDump.txt
   SET APPX_PACKAGEDUMP_NEW=
   SET APPX_BACKUPTIMESTAMP=^^!DATE:~-4^^!^^!DATE:~3,2^^!^^!DATE:~0,2^^!_^^!TIME:~0,2^^!^^!TIME:~3,2^^!^^!TIME:~6,2^^!
   SET APPX_BACKUPBASEPATH=%WORKINGDIR%\Backup
   SET APPX_BACKUPBASEPATH_NEW=
   SET APPX_BACKUPMAINPATH=
   SET APPX_PARAMOK=FALSE
   SET APPX_PACKAGENAME=
   SET APPX_ISINBOX=
   SET APPX_ISINBOX_DUMP=
   SET APPX_DATABASEOK=FALSE
   DEL /A /F /Q "%APPX_PACKAGEDUMP_TEMP%" >NUL 2>&1
   MKDIR "%APPX_BACKUPBASEPATH%" >NUL 2>&1
   VERIFY >NUL

   REM ### Define Resource related Paths and Script Constants ###
   SET RES_SQL_HEADERTEXT=%WORKINGDIR%\Resources\SQL\SQLHeaderText.res
   SET RES_SCRIPT_TITLETEXT=%WORKINGDIR%\Resources\Script\ScriptTitleText.res

   REM ### Define SQL-Script related Paths and Script Constants ###
   SET SQL_SYNCTIME=1000
   SET SQL_FILESOK=FALSE
   SET SQL_EXPORTPACKAGELIST=%SOURCEPATH%\SQL\ExportPackageList.sql
   SET SQL_BUILDSQLSTATEMENTS_ORIG=%WORKINGDIR%\SQL\BuildSQLStatements.sql
   SET SQL_BUILDSQLSTATEMENTS_TEMP=%TEMP%\BuildSQLStatements.sql
   SET SQL_DROPTRIGGERS_TEMP=%TEMP%\DropTriggers.sql
   SET SQL_CREATETRIGGERS_TEMP=%TEMP%\CreateTriggers.sql
   SET SQL_MODIFYAPPXDB_TEMP=%TEMP%\ModifyAppxDB.sql
   SET SQL_RESULTSCRIPT=%WORKINGDIR%\ResultScript.sql
   DEL /A /F /Q "%SQL_BUILDSQLSTATEMENTS_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_DROPTRIGGERS_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_CREATETRIGGERS_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_MODIFYAPPXDB_TEMP%" >NUL 2>&1
   VERIFY >NUL

REM ###########################################################################################################

   REM ### Check Administrator Privileges ###
   NET SESSION >NUL 2>&1
   IF !ERRORLEVEL!==0 (
      GOTO ADMIN
   ) ELSE (
      GOTO NOADMIN
   )

:ADMIN

   REM ### Scipt is running with Administrator Privileges ###
   DEL /A /F /Q "%TEMP%\GETADMIN.VBS" >NUL 2>&1
   VERIFY >NUL
   GOTO START

:NOADMIN

   REM ### Scipt is running without Administrator Privileges ###
   SET PARAMS=%*
   IF DEFINED PARAMS SET PARAMS=!PARAMS:"=""!
   ECHO Set UAC=CreateObject^("Shell.Application"^)>"%TEMP%\GETADMIN.VBS"
   ECHO UAC.ShellExecute "CMD", "/C """"%~f0"" %PARAMS%""", "", "runas", ^1>>"%TEMP%\GETADMIN.VBS"
   EXPLORER "%TEMP%\GETADMIN.VBS" >NUL 2>&1
   VERIFY >NUL
   GOTO EXIT

REM ###########################################################################################################

:START

   REM ### Display Title Message and Disclaimer ###
   CLS
   ECHO [1m[4m%TITLE%[24m[0m
   ECHO.
   SET ERRORCODE=0
   IF EXIST "%RES_SCRIPT_TITLETEXT%" (
      FOR /F "usebackq tokens=* delims=" %%A IN ("%RES_SCRIPT_TITLETEXT%") DO (ECHO %%A)
   ) ELSE (
      SET ERRORCODE=1
      SET ERRORMODULE=MAIN
      SET ERRORSOURCE=Resource File missing
      ECHO [101;93mERROR:[0m [93mResource File not found^^![0m
      ECHO.
      ECHO The Resource File "%RES_SCRIPT_TITLETEXT%"
      ECHO is missing^^! Please check your Installation Source or redownload the Script.
      GOTO ERROR
   )
   ECHO.
   PAUSE
   GOTO MAINMENU

REM ###########################################################################################################

:MAINMENU

   REM ### Display Main Menu of this Script ###
   CLS
   ECHO [1m[4m%TITLE%[24m[0m
   ECHO.
   SET ERRORCODE=0
   SET CHOICE=
   SET OPERATION=
   SET RUNMODE=NORMAL
   ECHO Please select the desired Action from the Menu.
   ECHO The Input for the Option is Case-Insensitive.
   ECHO.
   ECHO   [93mAppx-Database File :  [0m[101;93m[%APPX_DATABASEPATH%][0m
   ECHO   [93mAppx-Package List  :  [0m[42;93m[%APPX_PACKAGELIST%][0m
   ECHO   [93mAppx-Package Dump  :  [0m[44;93m[%APPX_PACKAGEDUMP%][0m
   ECHO.
   ECHO   [93mBackup-Directory   :  [0m[103;35m[%APPX_BACKUPBASEPATH%][0m
   ECHO.
   ECHO   [7m[B][0m : (B)ackup all Appx-Database Files (*.srd*)
   ECHO   [7m[D][0m : (D)ump Package List from Appx-Database into a Text File
   ECHO   [7m[M][0m : (M)odify Appx-Database to change the Protection of Packages
   ECHO   [7m   [0m
   ECHO   [7m[T][0m : (T)est-Mode: Only create SQL-File without altering the Database
   ECHO   [7m   [0m
   ECHO   [7m[1][0m : (1) Select another Appx-Database File
   ECHO   [7m[2][0m : (2) Select another Appx-Package List File
   ECHO   [7m[3][0m : (3) Select another Appx-Package Dump File
   ECHO   [7m[3][0m : (4) Select another Backup-Directory
   ECHO   [7m   [0m
   ECHO   [7m[R][0m : (R)estore Default File Paths and Settings
   ECHO   [7m   [0m
   ECHO   [7m[Q][0m : (Q)uit Application
   ECHO.
   SET /P "CHOICE=Selection [B/D/M/T/1-4/R/Q] (Q): "
   IF NOT %ERRORLEVEL%==0 (SET "OPERATION=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO EXIT)
   IF NOT DEFINED CHOICE (SET "OPERATION=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO EXIT)
   IF /I "%CHOICE%"=="Q" (SET "OPERATION=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO EXIT)
   IF /I "%CHOICE%"=="B" (SET "OPERATION=BACKUPDATABASE" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO CHOICE_!OPERATION!)
   IF /I "%CHOICE%"=="D" (SET "OPERATION=EXPORTAPPXLIST" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO CHOICE_!OPERATION!)
   IF /I "%CHOICE%"=="M" (SET "OPERATION=MODIFYDATABASE" & SET "RUNMODE=NORMAL" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO CHOICE_!OPERATION!)
   IF /I "%CHOICE%"=="T" (SET "OPERATION=MODIFYDATABASE" & SET "RUNMODE=TEST" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO CHOICE_!OPERATION!)
   IF /I "%CHOICE%"=="1" (SET "OPERATION=SWITCHDATABASE" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO CHOICE_!OPERATION!)
   IF /I "%CHOICE%"=="2" (SET "OPERATION=SWITCHAPPXLIST" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO CHOICE_!OPERATION!)
   IF /I "%CHOICE%"=="3" (SET "OPERATION=SWITCHAPPXDUMP" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO CHOICE_!OPERATION!)
   IF /I "%CHOICE%"=="4" (SET "OPERATION=SWITCHBKPFOLDR" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO CHOICE_!OPERATION!)
   IF /I "%CHOICE%"=="R" (SET "OPERATION=RESTOREDEFAULT" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO CHOICE_!OPERATION!)
   ECHO.
   ECHO [101;93mERROR:[0m [93mInvalid Argument^^![0m
   ECHO.
   ECHO "%CHOICE%" is not a valid Option^^!
   ECHO Please select one of the following Options [B/D/M/T/1-4/R/Q].
   ECHO.
   PAUSE
   VERIFY >NUL
   GOTO MAINMENU

REM ###########################################################################################################

:CHOICE_BACKUPDATABASE

   REM ### Backup all Appx-Database Files (*.srd*) ###
   CLS
   ECHO [1m[4m%TITLE%[24m[0m
   ECHO.
   SET ERRORCODE=0
   SET CHOICE=
   SET APPX_BACKUPMAINPATH=
   ECHO [7mBackup all Appx-Database Files (*.srd*)[0m
   ECHO.
   ECHO A Backup Copy of all relevant Appx-Database Files (*.srd*) within the currently
   ECHO selected Appx-Database Directory will be create at the following Location.
   ECHO.
   ECHO [93mAppx-Database File :[0m [101;93m[%APPX_DATABASEPATH%][0m
   ECHO [93mBackup-Directory   :[0m [103;35m[%APPX_BACKUPBASEPATH%][0m
   ECHO.
   SET /P "CHOICE=Do you wish to continue? [Y]/[N] (N): "
   IF NOT %ERRORLEVEL%==0 (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF NOT DEFINED CHOICE (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%CHOICE%"=="N" (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%CHOICE%"=="Y" (VERIFY >NUL & GOTO CHOICE_BACKUPDATABASE_CONTINUE)
   ECHO.
   ECHO [101;93mERROR:[0m [93mInvalid Argument^^![0m
   ECHO.
   ECHO "%CHOICE%" is not a valid Option^^!
   ECHO Please select one of the following Options [Y/N].
   ECHO.
   PAUSE
   VERIFY >NUL
   GOTO CHOICE_BACKUPDATABASE

:CHOICE_BACKUPDATABASE_CONTINUE

   REM ### Create Backup of the current Appx-DB ###
   ECHO.
   ECHO Creating Backup of the current Appx-DB...
   SET "APPX_BACKUPMAINPATH=%APPX_BACKUPTIMESTAMP%" & SET "APPX_BACKUPMAINPATH=!APPX_BACKUPBASEPATH!\AppxDB_!APPX_BACKUPMAINPATH: =0!"
   MKDIR "%APPX_BACKUPMAINPATH%" %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=MKDIR" & GOTO ERROR)
   XCOPY "%APPX_DATABASEPATH%\..\*.srd*" "%APPX_BACKUPMAINPATH%" /C /I /Q /H /R /Y %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=XCOPY" & GOTO ERROR)
   ECHO [92mBackup successfully created at:[0m [96m[%APPX_BACKUPMAINPATH%][0m

   SET CHOICE=
   SET APPX_BACKUPMAINPATH=
   SET ERRORCODE=0
   VERIFY >NUL
   GOTO FINISH

REM ###########################################################################################################

:CHOICE_EXPORTAPPXLIST

   REM ### Dump Package List from Appx-Database into a Text File ###
   CLS
   ECHO [1m[4m%TITLE%[24m[0m
   ECHO.
   SET ERRORCODE=0
   SET CHOICE=
   SET /A STEPINDEX=0
   SET /A SUBSTEPINDEX=0
   ECHO [7mDump Package List from Appx-Database into a Text File[0m
   ECHO.
   ECHO A List of all Packages in the Appx-Database and thier respective Configuration
   ECHO will be exported into a Text File at the following Location.
   ECHO.
   ECHO [93mAppx-Package Dump:[0m [44;93m[%APPX_PACKAGEDUMP%][0m
   ECHO.
   SET /P "CHOICE=Do you wish to continue? [Y]/[N] (N): "
   IF NOT %ERRORLEVEL%==0 (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF NOT DEFINED CHOICE (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%CHOICE%"=="N" (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%CHOICE%"=="Y" (VERIFY >NUL & GOTO CHOICE_EXPORTAPPXLIST_CONTINUE)
   ECHO.
   ECHO [101;93mERROR:[0m [93mInvalid Argument^^![0m
   ECHO.
   ECHO "%CHOICE%" is not a valid Option^^!
   ECHO Please select one of the following Options [Y/N].
   ECHO.
   PAUSE
   VERIFY >NUL
   GOTO CHOICE_EXPORTAPPXLIST

:CHOICE_EXPORTAPPXLIST_CONTINUE

   REM ### Create Package-Dump from Appx-DB ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   ECHO %STEPINDEX%. Creating Package-Dump from Appx-DB...
   DEL /A /F /Q "%APPX_PACKAGEDUMP_TEMP%" >NUL 2>&1
   VERIFY >NUL
   %RUNASSYSTEM% ""%SQLITE%" "%APPX_DATABASEPATH%" < "%SQL_EXPORTPACKAGELIST%" > "%APPX_PACKAGEDUMP_TEMP%"" %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=SQLITE" & GOTO ERROR)
   %CMDSYNCWAIT% %SQL_SYNCTIME% %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=NIRCMD" & GOTO ERROR)
   TASKLIST | FINDSTR /I /L /C:"NIRCMD.EXE" /C:"SQLITE.EXE" >NUL 2>&1
      IF %ERRORLEVEL%==0 (SET "ERRORCODE=1" & SET "ERRORMODULE=SQLSYNC" & SET "ERRORSOURCE=SQL-Tasks out of Sync" & GOTO ERROR)
   VERIFY >NUL
   ECHO [92mSQL-Transactions completed successfully.[0m

   REM ### Export Package-List to Target Folder ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   ECHO %STEPINDEX%. Exporting Package-List to Target Folder...
   IF EXIST "%APPX_PACKAGEDUMP_TEMP%" (
      XCOPY "%APPX_PACKAGEDUMP_TEMP%" "%APPX_PACKAGEDUMP%*" /C /I /Q /H /R /Y %ERRORHANDLER%
      IF NOT !ERRORLEVEL!==0 (SET "ERRORCODE=!ERRORLEVEL!" & SET "ERRORMODULE=XCOPY" & GOTO ERROR)
   ) ELSE (
      SET ERRORCODE=1
      SET ERRORMODULE=SQLSCRIPT
      SET ERRORSOURCE=Appx-Package Dump not found
      GOTO ERROR
   )

   DEL /A /F /Q "%APPX_PACKAGEDUMP_TEMP%" >NUL 2>&1
   VERIFY >NUL
   ECHO [92mDump successfully created at:[0m [96m[%APPX_PACKAGEDUMP%][0m
   ECHO.
   ECHO [92mAll Packages have been Exported successfully.[0m

   SET CHOICE=
   SET /A STEPINDEX=0
   SET /A SUBSTEPINDEX=0
   SET ERRORCODE=0
   VERIFY >NUL
   GOTO FINISH

REM ###########################################################################################################

:CHOICE_MODIFYDATABASE

   REM ### Modify Appx-Database to change the Protection of Packages or Run in Test-Mode ###
   CLS
   ECHO [1m[4m%TITLE%[24m[0m
   ECHO.
   SET ERRORCODE=0
   SET CHOICE=
   SET /A STEPINDEX=0
   SET /A SUBSTEPINDEX=0
   SET BREAK_A=
   SET BREAK_B=
   SET APPX_BACKUPMAINPATH=
   SET APPX_PARAMOK=FALSE
   SET APPX_PACKAGENAME=
   SET APPX_ISINBOX=
   SET APPX_ISINBOX_DUMP=
   SET APPX_DATABASEOK=FALSE
   SET SQL_FILESOK=FALSE

   IF %RUNMODE%==NORMAL (
      ECHO [7mModify Appx-Database to change the Protection of Packages[0m
      ECHO.
      ECHO [93m[4mWARNING:[24m[0m [101;93mIn the following Process the Appx-Database of Windows will be modified.[0m
      ECHO          [101;93mA Backup of all relevant Files will be created. If anything goes wrong,[0m
      ECHO          [101;93myou should shut down your PC immediately, and restore the damaged Files[0m
      ECHO          [101;93mwith those from the Backup, otherwise your Operating System will become[0m
      ECHO          [101;93mdamaged^^!^^!^^!                                                             [0m
      ECHO.         [101;93m                                                                       [0m
      ECHO          [101;93mYou may have to replace damaged Files offline, because they are openend[0m
      ECHO          [101;93mand locked by Windows while running.                                   [0m
      ECHO.         [101;93m                                                                       [0m
      ECHO          [101;93m[4mI will not take any Responsibilities for Problems or damaged Systems in[24m[0m
      ECHO          [101;93m[4many Case. It is up to you if you want to use this Software.[24m            [0m
      ECHO.
   ) ELSE (
      ECHO [7mTest-Mode: Only create SQL-File without altering the Database[0m
      ECHO.
      ECHO [93m[4mINFO:[24m[0m [103;91mIn the following Process a Test Run ist started to test the Modification[0m
      ECHO       [103;91mof the Appx-Database. [4mThe Database itself will not be modified.[24m Only the[0m
      ECHO       [103;91mnecesseray dynamic SQL-File^(s^) will be generated and can then be checked[0m
      ECHO       [103;91mfor correctness afterwards.                                             [0m
      ECHO.      [103;91m                                                                        [0m
      ECHO       [103;91m[4mI will not take any Responsibilities for Problems or damaged Systems in[24m [0m
      ECHO       [103;91m[4many Case. It is up to you if you want to use this Software.[24m             [0m
      ECHO.
   )

   SET /P "CHOICE=Do you wish to continue? [Y]/[N] (N): "
   IF NOT %ERRORLEVEL%==0 (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF NOT DEFINED CHOICE (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%CHOICE%"=="N" (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%CHOICE%"=="Y" (VERIFY >NUL & GOTO CHOICE_MODIFYDATABASE_CONTINUE)
   ECHO.
   ECHO [101;93mERROR:[0m [93mInvalid Argument^^![0m
   ECHO.
   ECHO "%CHOICE%" is not a valid Option^^!
   ECHO Please select one of the following Options [Y/N].
   ECHO.
   PAUSE
   VERIFY >NUL
   GOTO CHOICE_MODIFYDATABASE

:CHOICE_MODIFYDATABASE_CONTINUE

   REM ### Prepare SQL-Script Environment ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   ECHO %STEPINDEX%. Preparing SQL-Script Environment...
   DEL /A /F /Q "%APPX_PACKAGEDUMP_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_BUILDSQLSTATEMENTS_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_DROPTRIGGERS_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_CREATETRIGGERS_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_MODIFYAPPXDB_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_RESULTSCRIPT%" >NUL 2>&1
   ECHO [92mOperation completed successfully.[0m
   VERIFY >NUL

   IF %RUNMODE%==TEST (GOTO MODIFYDATABASE_SKIPBACKUP)

   REM ### Create Backup of the current Appx-DB ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   ECHO %STEPINDEX%. Creating Backup of the current Appx-DB...
   SET "APPX_BACKUPMAINPATH=%APPX_BACKUPTIMESTAMP%" & SET "APPX_BACKUPMAINPATH=!APPX_BACKUPBASEPATH!\AppxDB_!APPX_BACKUPMAINPATH: =0!"
   MKDIR "%APPX_BACKUPMAINPATH%" %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=MKDIR" & GOTO ERROR)
   XCOPY "%APPX_DATABASEPATH%\..\*.srd*" "%APPX_BACKUPMAINPATH%" /C /I /Q /H /R /Y %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=XCOPY" & GOTO ERROR)
   ECHO [92mBackup successfully created at:[0m [96m[%APPX_BACKUPMAINPATH%][0m

:MODIFYDATABASE_SKIPBACKUP

   REM ### Copy temporary SQL-Export Script Files ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   ECHO %STEPINDEX%. Copying temporary SQL-Export Script Files...
   XCOPY "%SQL_BUILDSQLSTATEMENTS_ORIG%" "%SQL_BUILDSQLSTATEMENTS_TEMP%*" /C /I /Q /H /R /Y %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=XCOPY" & GOTO ERROR)
   "%FART%" -i -q "%SQL_BUILDSQLSTATEMENTS_TEMP%" "[DropTriggers]" "%SQL_DROPTRIGGERS_TEMP:\=/%" >NUL 2>&1
   "%FART%" -i -q "%SQL_BUILDSQLSTATEMENTS_TEMP%" "[CreateTriggers]" "%SQL_CREATETRIGGERS_TEMP:\=/%" >NUL 2>&1
   VERIFY >NUL
   ECHO [92mOperation completed successfully.[0m

   REM ### Create Backup of Triggers and Statements from Appx-DB ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   ECHO %STEPINDEX%. Creating Backup of Triggers and Statements from Appx-DB. Please wait...
   %RUNASSYSTEM% ""%SQLITE%" "%APPX_DATABASEPATH%" < "%SQL_BUILDSQLSTATEMENTS_TEMP%"" %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=SQLITE" & GOTO ERROR)
   %CMDSYNCWAIT% %SQL_SYNCTIME% %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=NIRCMD" & GOTO ERROR)
   TASKLIST | FINDSTR /I /L /C:"NIRCMD.EXE" /C:"SQLITE.EXE" >NUL 2>&1
      IF %ERRORLEVEL%==0 (SET "ERRORCODE=1" & SET "ERRORMODULE=SQLSYNC" & SET "ERRORSOURCE=SQL-Tasks out of Sync" & GOTO ERROR)
   VERIFY >NUL
   SET SQL_FILESOK=TRUE
   IF NOT EXIST "%SQL_DROPTRIGGERS_TEMP%" SET SQL_FILESOK=FALSE
   IF NOT EXIST "%SQL_CREATETRIGGERS_TEMP%" SET SQL_FILESOK=FALSE
   IF %SQL_FILESOK%==FALSE (SET "ERRORCODE=1" & SET "ERRORMODULE=SQLSCRIPT" & SET "ERRORSOURCE=SQL-File(s) not created" & GOTO ERROR)
   ECHO [92mSQL-Transactions completed successfully.[0m

   REM ### Build new dynamic SQL-Script to update the Appx-DB ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   ECHO %STEPINDEX%. Building new dynamic SQL-Script to update the Appx-DB...
   REM ### Insert Header Text into the new SQL Script ###
   IF EXIST "%RES_SQL_HEADERTEXT%" (
      TYPE "%RES_SQL_HEADERTEXT%" > "%SQL_MODIFYAPPXDB_TEMP%"
      IF NOT !ERRORLEVEL!==0 (SET "ERRORCODE=!ERRORLEVEL!" & SET "ERRORMODULE=TYPE" & SET "ERRORSOURCE=TYPE" & GOTO ERROR)
      ECHO.>>"%SQL_MODIFYAPPXDB_TEMP%"
   ) ELSE (
      SET ERRORCODE=1
      SET ERRORMODULE=MAIN
      SET ERRORSOURCE=Resource File missing
      ECHO.
      ECHO [101;93mERROR:[0m [93mResource File not found^^![0m
      ECHO.
      ECHO The Resource File "%RES_SQL_HEADERTEXT%"
      ECHO is missing^^! Please check your Installation Source or redownload the Script.
      GOTO ERROR
   )

   REM ### Insert previously generated SQL-Script to drop Triggers into the new SQL-Script ###
   IF EXIST "%SQL_DROPTRIGGERS_TEMP%" (
      ECHO.>>"%SQL_MODIFYAPPXDB_TEMP%"
      ECHO -- Temporarily Drop all Triggers from the Appx Database to avoid Errors>>"%SQL_MODIFYAPPXDB_TEMP%"
      ECHO.>>"%SQL_MODIFYAPPXDB_TEMP%"
      TYPE "%SQL_DROPTRIGGERS_TEMP%" >> "%SQL_MODIFYAPPXDB_TEMP%"
      IF NOT !ERRORLEVEL!==0 (SET "ERRORCODE=!ERRORLEVEL!" & SET "ERRORMODULE=TYPE" & SET "ERRORSOURCE=TYPE" & GOTO ERROR)
   ) ELSE (
      SET ERRORCODE=1
      SET ERRORMODULE=SQLSCRIPT
      SET ERRORSOURCE=SQL-DropTriggers Script not found
      ECHO.
      ECHO [101;93mERROR:[0m [93mSQL-DropTriggers Script not found^^![0m
      ECHO.
      ECHO The SQL-Script "%SQL_DROPTRIGGERS_TEMP%"
      ECHO is missing or could not be created by the Script^^!
      GOTO ERROR
   )

   REM ### Parse Packagelist and insert Update Statement for each Package into the new SQL-Script ###
   IF EXIST "%APPX_PACKAGELIST%" (
      ECHO.>>"%SQL_MODIFYAPPXDB_TEMP%"
      ECHO -- Update the IsInbox Values in the Package Table to lock or unlock Appx Packages>>"%SQL_MODIFYAPPXDB_TEMP%"
      ECHO.>>"%SQL_MODIFYAPPXDB_TEMP%"
      FOR /F "usebackq tokens=* delims=" %%A IN ("%APPX_PACKAGELIST%") DO (
         ECHO %%A|FINDSTR /I /L /C:"#" >NUL 2>&1
         IF NOT !ERRORLEVEL!==0 (
            VERIFY >NUL
            SET APPX_PARAMOK=TRUE
            SET APPX_PACKAGENAME=
            SET APPX_ISINBOX=
            FOR /F "tokens=1,2 delims==" %%B IN ("%%A") DO (SET "APPX_PACKAGENAME=%%B" & SET "APPX_ISINBOX=%%C")
            IF NOT DEFINED APPX_PACKAGENAME SET APPX_PARAMOK=FALSE
            IF NOT DEFINED APPX_ISINBOX SET APPX_PARAMOK=FALSE
            IF !APPX_PARAMOK!==FALSE (SET "ERRORCODE=1" & SET "ERRORMODULE=APPXLIST" & SET "ERRORSOURCE=Parsing Error in Appx-Package List" & GOTO ERROR)
            ECHO UPDATE Package SET IsInbox=!APPX_ISINBOX! WHERE PackageFullName LIKE "%%!APPX_PACKAGENAME!%%";>>"%SQL_MODIFYAPPXDB_TEMP%"
         )
      )
   ) ELSE (
      SET ERRORCODE=1
      SET ERRORMODULE=APPXLIST
      SET ERRORSOURCE=Appx-Package List not found
      ECHO.
      ECHO [101;93mERROR:[0m [93mAppx-Package List not found^^![0m
      ECHO.
      ECHO The Appx-Package List "%APPX_PACKAGELIST%"
      ECHO could not be found^^!
      GOTO ERROR
   )

   REM ### Insert previously generated SQL-Script to recreate Triggers into the new SQL-Script ###
   IF EXIST "%SQL_CREATETRIGGERS_TEMP%" (
      ECHO.>>"%SQL_MODIFYAPPXDB_TEMP%"
      ECHO -- Recreate all Triggers of the Appx Database>>"%SQL_MODIFYAPPXDB_TEMP%"
      ECHO.>>"%SQL_MODIFYAPPXDB_TEMP%"
      TYPE "%SQL_CREATETRIGGERS_TEMP%" >> "%SQL_MODIFYAPPXDB_TEMP%"
      IF NOT !ERRORLEVEL!==0 (SET "ERRORCODE=!ERRORLEVEL!" & SET "ERRORMODULE=TYPE" & SET "ERRORSOURCE=TYPE" & GOTO ERROR)
   ) ELSE (
      SET ERRORCODE=1
      SET ERRORMODULE=SQLSCRIPT
      SET ERRORSOURCE=SQL-CreateTriggers Script not found
      ECHO.
      ECHO [101;93mERROR:[0m [93mSQL-CreateTriggers Script not found^^![0m
      ECHO.
      ECHO The SQL-Script "%SQL_CREATETRIGGERS_TEMP%"
      ECHO is missing or could not be created by the Script^^!
      GOTO ERROR
   )

   REM ### Insert Statement to save the modified Appx-DB into the new SQL-Script ###
   ECHO.>>"%SQL_MODIFYAPPXDB_TEMP%"
   ECHO .save "%APPX_DATABASEPATH:\=/%">>"%SQL_MODIFYAPPXDB_TEMP%"
      IF NOT EXIST "%SQL_MODIFYAPPXDB_TEMP%" (SET "ERRORCODE=1" & SET "ERRORMODULE=SQLSCRIPT" & SET "ERRORSOURCE=SQL-File(s) not created" & GOTO ERROR)
   ECHO [92mOperation completed successfully.[0m

   REM ### Copy generated SQL-Script to Working Directory ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   ECHO %STEPINDEX%. Copying generated SQL-Script to Working Directory...
   XCOPY "%SQL_MODIFYAPPXDB_TEMP%" "%SQL_RESULTSCRIPT%*" /C /I /Q /H /R /Y %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=XCOPY" & GOTO ERROR)
   ECHO [92mScript Copy successfully generated at:[0m [96m[%SQL_RESULTSCRIPT%][0m

   IF %RUNMODE%==TEST (GOTO MODIFYDATABASE_SKIPMODIFICATION)

   REM ### Update Packages in Appx-Database ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   ECHO %STEPINDEX%. Updating Packages in Appx-Database. Please wait...
   %RUNASSYSTEM% ""%SQLITE%" "%APPX_DATABASEPATH%" < "%SQL_MODIFYAPPXDB_TEMP%"" %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=SQLITE" & GOTO ERROR)
   %CMDSYNCWAIT% %SQL_SYNCTIME% %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=NIRCMD" & GOTO ERROR)
   TASKLIST | FINDSTR /I /L /C:"NIRCMD.EXE" /C:"SQLITE.EXE" >NUL 2>&1
      IF %ERRORLEVEL%==0 (SET "ERRORCODE=1" & SET "ERRORMODULE=SQLSYNC" & SET "ERRORSOURCE=SQL-Tasks out of Sync" & GOTO ERROR)
   VERIFY >NUL
   ECHO [92mSQL-Transactions completed successfully.[0m

   REM ### Verify Database Contents ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   SET /A SUBSTEPINDEX=0
   ECHO %STEPINDEX%. Verifying Database Contents. Please wait...
   REM ### Export Package-List from Appx-DB ###
   ECHO.
   SET /A SUBSTEPINDEX=%SUBSTEPINDEX%+1
   ECHO %STEPINDEX%.%SUBSTEPINDEX% Exporting Package-List from Appx-DB...
   %RUNASSYSTEM% ""%SQLITE%" "%APPX_DATABASEPATH%" < "%SQL_EXPORTPACKAGELIST%" > "%APPX_PACKAGEDUMP_TEMP%"" %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=SQLITE" & GOTO ERROR)
   %CMDSYNCWAIT% %SQL_SYNCTIME% %ERRORHANDLER%
      IF NOT %ERRORLEVEL%==0 (SET "ERRORCODE=%ERRORLEVEL%" & SET "ERRORMODULE=NIRCMD" & GOTO ERROR)
   TASKLIST | FINDSTR /I /L /C:"NIRCMD.EXE" /C:"SQLITE.EXE" >NUL 2>&1
      IF %ERRORLEVEL%==0 (SET "ERRORCODE=1" & SET "ERRORMODULE=SQLSYNC" & SET "ERRORSOURCE=SQL-Tasks out of Sync" & GOTO ERROR)
   VERIFY >NUL
   ECHO [92mSQL-Transactions completed successfully.[0m

   REM ### Check updated Values in Appx-Database ###
   ECHO.
   SET /A SUBSTEPINDEX=%SUBSTEPINDEX%+1
   ECHO %STEPINDEX%.%SUBSTEPINDEX% Checking updated Values in Appx-Database...
   SET APPX_DATABASEOK=TRUE
   IF EXIST "%APPX_PACKAGELIST%" (
      IF EXIST "%APPX_PACKAGEDUMP_TEMP%" (
         SET BREAK_A=
         SET BREAK_B=
         FOR /F "usebackq tokens=* delims=" %%A IN ("%APPX_PACKAGELIST%") DO (
            IF NOT DEFINED BREAK_A (
               ECHO %%A|FINDSTR /I /L /C:"#" >NUL 2>&1
               IF NOT !ERRORLEVEL!==0 (
                  VERIFY >NUL
                  SET APPX_PARAMOK=TRUE
                  SET APPX_PACKAGENAME=
                  SET APPX_ISINBOX=
                  FOR /F "tokens=1,2 delims==" %%B IN ("%%A") DO (SET "APPX_PACKAGENAME=%%B" & SET "APPX_ISINBOX=%%C")
                  IF NOT DEFINED APPX_PACKAGENAME SET APPX_PARAMOK=FALSE
                  IF NOT DEFINED APPX_ISINBOX SET APPX_PARAMOK=FALSE
                  IF !APPX_PARAMOK!==FALSE (SET "APPX_DATABASEOK=FALSE" & SET "ERRORCODE=1" & SET "ERRORMODULE=APPXLIST" & SET "ERRORSOURCE=Parsing Error in Appx-Package List" & GOTO ERROR)
                  SET APPX_ISINBOX_DUMP=
                  SET BREAK_B=
                  FOR /F "tokens=2 delims= " %%B IN ('FINDSTR /I /L /C:"!APPX_PACKAGENAME!" "%APPX_PACKAGEDUMP_TEMP%" 2^>NUL') DO (
                     IF NOT DEFINED BREAK_B (
                        SET APPX_ISINBOX_DUMP=%%B
                        IF NOT DEFINED APPX_ISINBOX_DUMP SET "APPX_DATABASEOK=FALSE" & SET "ERRORCODE=1" & SET "ERRORMODULE=APPXDUMP" & SET "ERRORSOURCE=Parsing Error in Appx-Package Dump" & GOTO ERROR
                        IF !APPX_ISINBOX_DUMP! NEQ !APPX_ISINBOX! (
                           SET APPX_DATABASEOK=FALSE
                           SET BREAK_A=TRUE
                           SET BREAK_B=TRUE
                        )
                     )
                  )
                  IF %SCRIPT_IGNOREMISSINGPKG%==FALSE (
                     IF NOT DEFINED APPX_ISINBOX_DUMP SET "APPX_DATABASEOK=FALSE" & SET "ERRORCODE=1" & SET "ERRORMODULE=APPXDUMP" & SET "ERRORSOURCE=Package not found in Appx-Package Dump" & GOTO ERROR
                  )
               )
            )
         )
      ) ELSE (
         SET APPX_DATABASEOK=FALSE
         SET ERRORCODE=1
         SET ERRORMODULE=SQLSCRIPT
         SET ERRORSOURCE=Appx-Package Dump not found
         GOTO ERROR
      )
   ) ELSE (
      SET APPX_DATABASEOK=FALSE
      SET ERRORCODE=1
      SET ERRORMODULE=SQLSCRIPT
      SET ERRORSOURCE=Appx-Package List not found
      GOTO ERROR
   )

   IF %APPX_DATABASEOK%==TRUE (
      ECHO [92mUpdated Values have been verified successfully.[0m
      ECHO.
      ECHO [92mAll configured Packages have been Updated successfully.[0m
   ) ELSE (
      ECHO [91mUpdated Values do not match the Configuration.[0m
      ECHO.
      ECHO [93m[4mWARNING:[24m[0m [101;93mOne or more Packages haven't been Updated correctly. Your System may be[0m
      ECHO          [101;93min an undefined State.  To prevent further damages you should shut down[0m
      ECHO          [101;93myour System immediately. You could restore the Appx-Database offline by[0m
      ECHO          [101;93mbooting into Windows Recovery Environment Console and copying all Files[0m
      ECHO          [101;93mfrom the Backup Directory to the following Location:                   [0m
      ECHO          [101;93m                                                                       [0m
      ECHO.         [101;93m%%ProgramData%%\Microsoft\Windows\AppRepository                          [0m
      ECHO          [101;93m                                                                       [0m
      ECHO          [101;93mThe easiest Way to get into Windows Recovery Environment Console, is to[0m
      ECHO          [101;93mclick "Reboot" in the Start-Menu while holding down the SHIFT Key.  You[0m
      ECHO          [101;93mare being led to a Selection Screen, where you have to select "Trouble-[0m
      ECHO          [101;93mshooting" -> "Advanced Options" -> "Command Prompt". You have to select[0m
      ECHO          [101;93ma User Account with Admin-Rights to enter the Console.  Find out, which[0m
      ECHO          [101;93mDrive Letter corresponds to the Windows-Partition, and which one to the[0m
      ECHO          [101;93mPartition containing your Backup Files. Then invoke this Command:      [0m
      ECHO          [101;93m                                                                       [0m
      ECHO          [101;93mXCOPY "X:\...\Backup\*.*" "Y:\ProgramData\...\AppRepository" /H /R /Y  [0m
      ECHO.         [101;93m                                                                       [0m
      ECHO          [101;93mX: Drive-Letter of the Partition containing the Backup Files           [0m
      ECHO          [101;93mY: Drive-Letter of the Windows Partition containing the Appx-Database  [0m
      ECHO.         [101;93m                                                                       [0m
      ECHO.         [101;93mAfter you have successfully restored the Database Files, reboot System.[0m
   )

:MODIFYDATABASE_SKIPMODIFICATION

   REM ### Reset SQL-Script Environment ###
   ECHO.
   SET /A STEPINDEX=%STEPINDEX%+1
   ECHO %STEPINDEX%. Resetting SQL-Script Environment...
   DEL /A /F /Q "%APPX_PACKAGEDUMP_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_BUILDSQLSTATEMENTS_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_DROPTRIGGERS_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_CREATETRIGGERS_TEMP%" >NUL 2>&1
   DEL /A /F /Q "%SQL_MODIFYAPPXDB_TEMP%" >NUL 2>&1
   ECHO [92mOperation completed successfully.[0m
   VERIFY >NUL

   SET CHOICE=
   SET /A STEPINDEX=0
   SET /A SUBSTEPINDEX=0
   SET BREAK_A=
   SET BREAK_B=
   SET APPX_BACKUPMAINPATH=
   SET APPX_PARAMOK=FALSE
   SET APPX_PACKAGENAME=
   SET APPX_ISINBOX=
   SET APPX_ISINBOX_DUMP=
   SET APPX_DATABASEOK=FALSE
   SET SQL_FILESOK=FALSE
   SET ERRORCODE=0
   VERIFY >NUL
   GOTO FINISH

REM ###########################################################################################################

:CHOICE_SWITCHDATABASE

   REM ### Select another Appx-Database File ###
   CLS
   ECHO [1m[4m%TITLE%[24m[0m
   ECHO.
   SET ERRORCODE=0
   SET APPX_DATABASEPATH_NEW=
   ECHO [7mSelect another Appx-Database File[0m
   ECHO.
   ECHO Please specify the Path to the Appx Deployment Database File.
   ECHO You may keep the Default File Path by just Pressing ENTER.
   ECHO.
   ECHO You can either enter the Path manually or Drag ^& Drop the
   ECHO File to this Window. Please use Double Quotes if the Path
   ECHO contains Spaces.
   ECHO.
   ECHO [93mCurrent Database File : [0m[101;93m[%APPX_DATABASEPATH%][0m
   SET /P "APPX_DATABASEPATH_NEW=[96mNew Database File     : [0m"
   IF NOT %ERRORLEVEL%==0 (SET "APPX_DATABASEPATH_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF NOT DEFINED APPX_DATABASEPATH_NEW (SET "APPX_DATABASEPATH_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   SET APPX_DATABASEPATH_NEW=%APPX_DATABASEPATH_NEW:"=%
   IF NOT DEFINED APPX_DATABASEPATH_NEW (SET "APPX_DATABASEPATH_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%APPX_DATABASEPATH_NEW%"=="%APPX_DATABASEPATH%" (SET "APPX_DATABASEPATH_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF EXIST "%APPX_DATABASEPATH_NEW%" (SET "APPX_DATABASEPATH=%APPX_DATABASEPATH_NEW%" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   ECHO.
   ECHO [101;93mERROR:[0m [93mFile not found^^![0m
   ECHO.
   ECHO "%APPX_DATABASEPATH_NEW%"
   ECHO.
   ECHO The specified File does not exist^^!
   ECHO Please specify a proper File Path.
   ECHO.
   PAUSE
   VERIFY >NUL
   GOTO CHOICE_SWITCHDATABASE

REM ###########################################################################################################

:CHOICE_SWITCHAPPXLIST

   REM ### Select another Appx-Package List File ###
   CLS
   ECHO [1m[4m%TITLE%[24m[0m
   ECHO.
   SET ERRORCODE=0
   SET APPX_PACKAGELIST_NEW=
   ECHO [7mSelect another Appx-Package List File[0m
   ECHO.
   ECHO Please specify the Path to the Package Manipulation List.
   ECHO You may keep the Default File Path by just Pressing ENTER.
   ECHO.
   ECHO You can either enter the Path manually or Drag ^& Drop the
   ECHO File to this Window. Please use Double Quotes if the Path
   ECHO contains Spaces.
   ECHO.
   ECHO [93mCurrent Package List File : [0m[42;93m[%APPX_PACKAGELIST%][0m
   SET /P "APPX_PACKAGELIST_NEW=[96mNew Package List File     : [0m"
   IF NOT %ERRORLEVEL%==0 (SET "APPX_PACKAGELIST_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF NOT DEFINED APPX_PACKAGELIST_NEW (SET "APPX_PACKAGELIST_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   SET APPX_PACKAGELIST_NEW=%APPX_PACKAGELIST_NEW:"=%
   IF NOT DEFINED APPX_PACKAGELIST_NEW (SET "APPX_PACKAGELIST_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%APPX_PACKAGELIST_NEW%"=="%APPX_PACKAGELIST%" (SET "APPX_PACKAGELIST_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF EXIST "%APPX_PACKAGELIST_NEW%" (SET "APPX_PACKAGELIST=%APPX_PACKAGELIST_NEW%" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   ECHO.
   ECHO [101;93mERROR:[0m [93mFile not found^^![0m
   ECHO.
   ECHO "%APPX_PACKAGELIST_NEW%"
   ECHO.
   ECHO The specified File does not exist^^!
   ECHO Please specify a proper File Path.
   ECHO.
   PAUSE
   VERIFY >NUL
   GOTO CHOICE_SWITCHAPPXLIST

REM ###########################################################################################################

:CHOICE_SWITCHAPPXDUMP

   REM ### Select another Appx-Package Dump File ###
   CLS
   ECHO [1m[4m%TITLE%[24m[0m
   ECHO.
   SET ERRORCODE=0
   SET APPX_PACKAGEDUMP_NEW=
   SET CHOICE=
   ECHO [7mSelect another Appx-Package Dump File[0m
   ECHO.
   ECHO Please specify the Path for the Package Dump Export List.
   ECHO You may keep the Default File Path by just Pressing ENTER.
   ECHO.
   ECHO You can either enter the Path manually or Drag ^& Drop the
   ECHO File to this Window. Please use Double Quotes if the Path
   ECHO contains Spaces.
   ECHO.
   ECHO If the File already exists it will be overwritten when a
   ECHO Dump is created.
   ECHO.
   ECHO [93mCurrent Package Dump File : [0m[44;93m[%APPX_PACKAGEDUMP%][0m
   SET /P "APPX_PACKAGEDUMP_NEW=[96mNew Package Dump File     : [0m"
   IF NOT %ERRORLEVEL%==0 (SET "APPX_PACKAGEDUMP_NEW=" & SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF NOT DEFINED APPX_PACKAGEDUMP_NEW (SET "APPX_PACKAGEDUMP_NEW=" & SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   SET APPX_PACKAGEDUMP_NEW=%APPX_PACKAGEDUMP_NEW:"=%
   IF NOT DEFINED APPX_PACKAGEDUMP_NEW (SET "APPX_PACKAGEDUMP_NEW=" & SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%APPX_PACKAGEDUMP_NEW%"=="%APPX_PACKAGEDUMP%" (SET "APPX_PACKAGEDUMP_NEW=" & SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)

:CHOICE_SWITCHAPPXDUMP_OVERWRITE

   SET ERRORCODE=0
   SET CHOICE=
   IF EXIST "%APPX_PACKAGEDUMP_NEW%" (
      ECHO.
      ECHO WARNING: The File you specified already exists
      ECHO          and will be overwritten^^!
      ECHO.
      SET /P "CHOICE=Do you wish to continue? [Y]/[N] (N): "
      IF NOT !ERRORLEVEL!==0 (VERIFY >NUL & GOTO CHOICE_SWITCHAPPXDUMP)
      IF NOT DEFINED CHOICE VERIFY >NUL & GOTO CHOICE_SWITCHAPPXDUMP
      IF /I "!CHOICE!"=="N" (VERIFY >NUL & GOTO CHOICE_SWITCHAPPXDUMP)
      IF /I "!CHOICE!"=="Y" (VERIFY >NUL & GOTO CHOICE_SWITCHAPPXDUMP_CONTINUE)
      ECHO.
      ECHO [101;93mERROR:[0m [93mInvalid Argument^^![0m
      ECHO.
      ECHO "!CHOICE!" is not a valid Option^^!
      ECHO Please select one of the following Options [Y/N].
      ECHO.
      PAUSE
      ECHO [1A [2K [1A [2K [1A [2K [1A [2K [1A [2K [1A [2K [1A [2K [1A [2K [1A [2K [1A [2K [1A [2K [1A [2K [1A
      VERIFY >NUL
      GOTO CHOICE_SWITCHAPPXDUMP_OVERWRITE
   )

:CHOICE_SWITCHAPPXDUMP_CONTINUE

   SET APPX_PACKAGEDUMP=%APPX_PACKAGEDUMP_NEW%
   SET APPX_PACKAGEDUMP_NEW=
   SET CHOICE=
   SET ERRORCODE=0
   VERIFY >NUL
   GOTO MAINMENU

REM ###########################################################################################################

:CHOICE_SWITCHBKPFOLDR

   REM ### Select another Backup-Directory ###
   CLS
   ECHO [1m[4m%TITLE%[24m[0m
   ECHO.
   SET ERRORCODE=0
   SET APPX_BACKUPBASEPATH_NEW=
   ECHO [7mSelect another Backup-Directory[0m
   ECHO.
   ECHO Please specify the Path to a Folder, where Backup Copies of
   ECHO the currently selected Appx-Database File are stored.
   ECHO You may keep the Default File Path by just Pressing ENTER.
   ECHO.
   ECHO You can either enter the Path manually or Drag ^& Drop the
   ECHO Folder to this Window. Please use Double Quotes if the Path
   ECHO contains Spaces.
   ECHO.
   ECHO [93mCurrent Backup-Directory : [0m[103;35m[%APPX_BACKUPBASEPATH%][0m
   SET /P "APPX_BACKUPBASEPATH_NEW=[96mNew Backup-Directory     : [0m"
   IF NOT %ERRORLEVEL%==0 (SET "APPX_BACKUPBASEPATH_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF NOT DEFINED APPX_BACKUPBASEPATH_NEW (SET "APPX_BACKUPBASEPATH_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   SET APPX_BACKUPBASEPATH_NEW=%APPX_BACKUPBASEPATH_NEW:"=%
   IF NOT DEFINED APPX_BACKUPBASEPATH_NEW (SET "APPX_BACKUPBASEPATH_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%APPX_BACKUPBASEPATH_NEW%"=="%APPX_BACKUPBASEPATH%" (SET "APPX_BACKUPBASEPATH_NEW=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)

   IF EXIST "%APPX_BACKUPBASEPATH_NEW%" (
      SET APPX_BACKUPBASEPATH=!APPX_BACKUPBASEPATH_NEW!
      ECHO.
      ECHO [92mSelected Backup-Directory is existing.[0m
      ECHO [92mBackup-Directory successfully switched to[0m [103;35m[!APPX_BACKUPBASEPATH!][0m
      ECHO.
      PAUSE
      SET APPX_BACKUPBASEPATH_NEW=
      SET ERRORCODE=0
      VERIFY >NUL
      GOTO MAINMENU
   ) ELSE (
      ECHO.
      ECHO [93mSelected Backup-Directory not existing. It will be created...[0m
      MKDIR "!APPX_BACKUPBASEPATH_NEW!" >NUL 2>&1
      IF !ERRORLEVEL!==0 (
         SET APPX_BACKUPBASEPATH=!APPX_BACKUPBASEPATH_NEW!
         ECHO [92mBackup-Directory successfully created.[0m
         ECHO [92mBackup-Directory successfully switched to[0m [103;35m[!APPX_BACKUPBASEPATH!][0m
         ECHO.
         PAUSE
         SET APPX_BACKUPBASEPATH_NEW=
         SET ERRORCODE=0
         VERIFY >NUL
         GOTO MAINMENU
      ) ELSE (
         ECHO [91mBackup-Directory could not be created.[0m
         ECHO [91mBackup-Directory will not be changed.[0m
         ECHO.
         ECHO Please select another Backup-Directory Path.
         ECHO.
         PAUSE
         SET APPX_BACKUPBASEPATH_NEW=
         SET ERRORCODE=0
         VERIFY >NUL
         GOTO CHOICE_SWITCHBKPFOLDR
      )
   )

REM ###########################################################################################################

:CHOICE_RESTOREDEFAULT

   REM ### Restore Default File Paths and Settings ###
   CLS
   ECHO [1m[4m%TITLE%[24m[0m
   ECHO.
   SET ERRORCODE=0
   SET CHOICE=
   ECHO [7mRestore Default File Paths and Settings[0m
   ECHO.
   ECHO Do you wish to Reset all File Paths and Settings to their Default Values?
   ECHO.
   ECHO [4mDefault Settings:[0m
   ECHO.
   ECHO   [93mAppx-Database File :  [0m[101;93m[%ProgramData%\Microsoft\Windows\AppRepository\StateRepository-Machine.srd][0m
   ECHO   [93mAppx-Package List  :  [0m[42;93m[%WORKINGDIR%\AppxPackageList.txt][0m
   ECHO   [93mAppx-Package Dump  :  [0m[44;93m[%WORKINGDIR%\AppxPackageDump.txt][0m
   ECHO.
   ECHO   [93mBackup-Directory   :  [0m[103;35m[%WORKINGDIR%\Backup][0m
   ECHO.
   SET /P "CHOICE=Do you wish to continue? [Y]/[N] (N): "
   IF NOT %ERRORLEVEL%==0 (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF NOT DEFINED CHOICE (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%CHOICE%"=="N" (SET "CHOICE=" & SET "ERRORCODE=0" & VERIFY >NUL & GOTO MAINMENU)
   IF /I "%CHOICE%"=="Y" (VERIFY >NUL & GOTO CHOICE_RESTOREDEFAULT_CONTINUE)
   ECHO.
   ECHO [101;93mERROR:[0m [93mInvalid Argument^^![0m
   ECHO.
   ECHO "%CHOICE%" is not a valid Option^^!
   ECHO Please select one of the following Options [Y/N].
   ECHO.
   PAUSE
   VERIFY >NUL
   GOTO CHOICE_RESTOREDEFAULT

:CHOICE_RESTOREDEFAULT_CONTINUE

   SET APPX_DATABASEPATH=%ProgramData%\Microsoft\Windows\AppRepository\StateRepository-Machine.srd
   SET APPX_PACKAGELIST=%WORKINGDIR%\AppxPackageList.txt
   SET APPX_PACKAGEDUMP=%WORKINGDIR%\AppxPackageDump.txt
   SET APPX_BACKUPBASEPATH=%WORKINGDIR%\Backup

   SET CHOICE=
   SET ERRORCODE=0
   VERIFY >NUL
   GOTO MAINMENU

REM ###########################################################################################################

:FINISH

   REM ### Common Entry Point after Finishing a Task ###

   REM ### Display common Finish Message after a Task has run ###
   ECHO.
   ECHO All Tasks have been completed^^! Press any Key to return to Main Menu.
   PAUSE
   SET ERRORCODE=0
   VERIFY >NUL
   GOTO MAINMENU

REM ###########################################################################################################

:ERROR

   REM ### Handle Errors occurred in this Script ###

   REM ### Check for Error Messages from the Consoles Standard Error ###
   IF NOT DEFINED ERRORSOURCE (
      IF EXIST "%ERROROUTPUT%" (
         SET ERRORSOURCE=
         FOR /F "usebackq tokens=* delims=" %%A IN ("%ERROROUTPUT%") DO (
            IF NOT DEFINED ERRORSOURCE (
               SET ERRORSOURCE=%%A
            ) ELSE (
               SET ERRORSOURCE=!ERRORSOURCE!!NL!%%A
            )
         )
         IF NOT DEFINED ERRORSOURCE SET ERRORSOURCE=UNKNOWNERROR
      ) ELSE (
         SET ERRORSOURCE=UNKNOWNERROR
      )
   )

   REM ### Display Error Message with detailed Infos ###
   ECHO.
   ECHO An Error has occurred during the Execution of this Script^^!
   ECHO.
   ECHO The following Error Details are provided...
   ECHO.
   ECHO   Error-Code   : %ERRORCODE%
   ECHO   Error-Module : %ERRORMODULE%
   ECHO   Error-Source : %ERRORSOURCE%
   ECHO.
   ECHO The Program will now be terminated.
   ECHO.
   PAUSE
   GOTO EXIT

:EXIT

   REM ### Cleanup all Variables and Files and exit this Script ###

   REM ### Reset Appx-DB related Paths and Script Constants ###
   IF DEFINED APPX_PACKAGEDUMP_TEMP DEL /A /F /Q "%APPX_PACKAGEDUMP_TEMP%" >NUL 2>&1
   SET APPX_DATABASEPATH=
   SET APPX_DATABASEPATH_NEW=
   SET APPX_PACKAGELIST=
   SET APPX_PACKAGELIST_NEW=
   SET APPX_PACKAGEDUMP=
   SET APPX_PACKAGEDUMP_TEMP=
   SET APPX_PACKAGEDUMP_NEW=
   SET APPX_BACKUPTIMESTAMP=
   SET APPX_BACKUPBASEPATH=
   SET APPX_BACKUPBASEPATH_NEW=
   SET APPX_BACKUPMAINPATH=
   SET APPX_PARAMOK=
   SET APPX_PACKAGENAME=
   SET APPX_ISINBOX=
   SET APPX_ISINBOX_DUMP=
   SET APPX_DATABASEOK=
   VERIFY >NUL

   REM ### Reset Resource related Paths and Script Constants ###
   SET RES_SQL_HEADERTEXT=
   SET RES_SCRIPT_TITLETEXT=

   REM ### Reset SQL-Script Environment ###
   IF DEFINED SQL_BUILDSQLSTATEMENTS_TEMP DEL /A /F /Q "!SQL_BUILDSQLSTATEMENTS_TEMP!" >NUL 2>&1
   IF DEFINED SQL_DROPTRIGGERS_TEMP DEL /A /F /Q "!SQL_DROPTRIGGERS_TEMP!" >NUL 2>&1
   IF DEFINED SQL_CREATETRIGGERS_TEMP DEL /A /F /Q "!SQL_CREATETRIGGERS_TEMP!" >NUL 2>&1
   IF DEFINED SQL_MODIFYAPPXDB_TEMP DEL /A /F /Q "!SQL_MODIFYAPPXDB_TEMP!" >NUL 2>&1
   SET SQL_SYNCTIME=
   SET SQL_FILESOK=
   SET SQL_EXPORTPACKAGELIST=
   SET SQL_BUILDSQLSTATEMENTS_ORIG=
   SET SQL_BUILDSQLSTATEMENTS_TEMP=
   SET SQL_DROPTRIGGERS_TEMP=
   SET SQL_CREATETRIGGERS_TEMP=
   SET SQL_MODIFYAPPXDB_TEMP=
   SET SQL_RESULTSCRIPT=
   VERIFY >NUL

   REM ### Reset Script Behavior Parameters ###
   SET SCRIPT_IGNOREMISSINGPKG=

   REM ### Reset additional Script Variables ###
   SET BREAK_A=
   SET BREAK_B=
   SET OPERATION=
   SET RUNMODE=
   SET STEPINDEX=
   SET SUBSTEPINDEX=

   REM ### Reset Macros for Function Calls ###
   SET RUNASSYSTEM=
   SET CMDSYNCWAIT=

   REM ### Reset Paths for Tools and Functions ###
   SET FART=
   SET NIRCMD=
   SET SQLITE=

   REM ### Reset Bitness Detection Variables ###
   SET BITNESS=

   REM ### Reset Version and Title Variables ###
   SET VERSION=
   SET TITLE=

   REM ### Reset Code Page Settings ###
   IF DEFINED CODEPAGE CHCP !CODEPAGE! >NUL 2>&1
   SET CODEPAGE=
   VERIFY >NUL

   REM ### Reset Error Handling Variables ###
   IF DEFINED ERROROUTPUT DEL /A /F /Q "%ERROROUTPUT%" >NUL 2>&1
   SET ERRORMODULE=
   SET ERRORSOURCE=
   SET ERROROUTPUT=
   SET ERRORHANDLER=
   SET LF=
   VERIFY >NUL

   REM ### Reset Script Workspace ###
   SET SOURCEPATH=
   SET WORKINGDIR=
   POPD >NUL 2>&1
   VERIFY >NUL

REM ###########################################################################################################

   REM ### Return from Variable Namespace ###
   ENDLOCAL & (^
      SET ERRORCODE=%ERRORCODE%
   )

CLS
EXIT /B %ERRORCODE%