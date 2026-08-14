echo off
set computer=%1
set guid=%2

:STAGE1
C:\Software\PStools\PSexec.exe \\%computer% msiexec /qn /x %guid% /forcerestart
IF %ERRORLEVEL% EQU 1641 GOTO RETRY1
GOTO ERROR

:IPTEST1
ECHO Waiting for the computer to reboot and come back online.
ping -n 1 %computer% | find "TTL=" >nul
if errorlevel 1 (
	goto RETRY1
) else (
	goto STAGE2
)

:RETRY1
TIMEOUT.exe /t 60 /NOBREAK
goto IPTEST1

:STAGE2
ECHO Computer has rebooted. Waiting 60 seconds and then attempting install.
TIMEOUT.exe /t 60 /NOBREAK
C:\Software\PStools\PSexec.exe \\%computer% cmd /c C:\Software\VMware-viewagent-6.1.0-2509441.exe /s /v "/qn VDM_VC_MANAGED_AGENT=1 VDM_FLASH_URL_REDIRECTION=1 ADDLOCAL=Core,SVIAgent,ThinPrint,USB,FlashURLRedirection,RTAV"
IF %ERRORLEVEL% EQU 1641 GOTO RETRY2
GOTO ERROR

:IPTEST2
ECHO Waiting for the computer to reboot and come back online.
ping -n 1 %computer% | find "TTL=" >nul
if errorlevel 1 (
	goto RETRY2
) else (
	goto STAGE3
)

:RETRY2
TIMEOUT.exe /t 60 /NOBREAK
goto IPTEST2

:STAGE3
ECHO Computer has rebooted. Waiting 60 seconds and then validating install.
TIMEOUT.exe /t 60 /NOBREAK

:ERROR
ECHO The installer/uninstaller failed. Review the above.
Pause

:END
Exit