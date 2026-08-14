echo off
set computer=%1
C:\Software\PStools\PSexec.exe \\%computer% msiexec /qn /x {0FBA03B4-529B-485a-A7BC-AF29C0790464} /forcerestart
TIMEOUT.exe /T 120 /NOBREAK
C:\Software\PStools\PSexec.exe \\%computer% cmd /c C:\Software\VMware-viewagent-x86_64-6.1.0-2509441.exe /s /v "/qn VDM_VC_MANAGED_AGENT=1 VDM_FLASH_URL_REDIRECTION=1 ADDLOCAL=Core,SVIAgent,ThinPrint,USB,FlashURLRedirection,RTAV"