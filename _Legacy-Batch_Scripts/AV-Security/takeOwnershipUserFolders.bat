set /p NAME=What is the username to take ownership of? 
IF [%NAME%]==[] GOTO END
takeown /f "\\SERVER\SHARE\%NAME%" /R /D Y
takeown /f "\\SERVER\SHARE\...\%NAME%"/R /D Y
takeown /f "\\SERVER\SHARE\%NAME%" /R /D Y
takeown /f "\\SERVER\SHARE\%NAME%" /R /D Y
takeown /f "\\SERVER\SHARE\...\%NAME%" /R /D Y
:END