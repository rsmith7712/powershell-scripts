@echo.
@echo Polling....
::@echo off

:: discover UFO_NUMBER
for /f "tokens=1,2* delims=sS" %%i in ('echo %COMPUTERNAME%') do set SITE=%%i&set COMP=%%j

::  Delete Prior Days Polling files and copy backup data
Del c:\PollXR650\*.Z*
Del C:\PollXR650\*.X*
Del C:\1650\*.* /Q
xCopy "C:\PollXR650\Backup" "\\%SITE%js\c$\Backup" /D /E /C /R /I /K /Y

:: Execute Polling and File Conversion
cd\Program Files\Datasym\Comm2000
comm2000.exe polling.cmd
CD\pollxr650
DOMAINCONV.EXE 00-%SITE%.DAT
SetLocal

:: prepare date/time stamp
for /f "Tokens=1-4 Delims=/ " %%i in ('date /t') do set dt=%%i-%%j-%%k-%%l
  for /f "Tokens=1" %%i in ('time /t') do set tm=-%%i

:: timestamp (yyyymmmdd-hhnnss)
set tm=%tm::=-%
set dtt=%dt%%tm%

:: directories
Set "sourcefolder=C:\PollXR650\"
Set "destinationfolder=C:\PollXR650\Backup\POLL-%dtt%"

:: copy files
For /f "delims=" %%a in (
  'Dir /a-D /b "%sourcefolder%\*.dat" 2^>nul'
  ) do If exist "%%a" (
  xcopy /c /d /i /y "%%a" "%destinationfolder%\"

)

EndLocal

::  Copy Files to 1650Folder & Backup Machine
Del c:\pollxr650\*.dat
xCopy "C:\PollXR650\*.*" "C:\1650" /D /E /C /R /I /K /Y
xCopy "C:\PollXR650\Backup" "\\%SITE%js\c$\Backup" /D /E /C /R /I /K /Y


:: Execute MakePLU & File Format Conversion
cd\Program Files\Domain, Inc\Datasynchronizer
MakePLUFile.exe
cd\Program Files\Datasym\IFC
If Exist C:\1650\PLU\plu.txt IFC.exe domain.aiw c:\1650\plu\plu.txt c:\pollxr650\plu\plu.p13


:: Execute LoadPlu
cd\Program Files\Datasym\Comm2000
If Exist C:\1650\PLU\plu.txt comm2000.exe LoadPLU.cmd
Del c:\1650\PLU\plu.txt


exit

