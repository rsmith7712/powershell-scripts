REM PowerShell script launcher from batch file



REM Prevents contents of batch file from being displayed
@ECHO OFF

REM Gets directory the file is in
SET ScriptDirectory=%~dp0

REM Appends the PowerShell script filename to script directory
REM to get full path to the Ps file; This is the only line you need to modify
SET PowerShellScriptPath=%ScriptDirectory%w32tm_status.ps1

REM This calls the PowerShell script
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%PowerShellScriptPath%""' -Verb RunAs};


REM pause