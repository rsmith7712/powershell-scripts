set /p NAME=What is the username to be deleted? 
IF [%NAME%]==[] GOTO END

takeown /f "\\SERVER\SHARE\%NAME%" /R /D Y

:END