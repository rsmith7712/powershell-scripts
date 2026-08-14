set /p NAME=What is the username to be deleted? 
IF [%NAME%]==[] GOTO END
takeown /f "\\SERVER\SHARE\%NAME%.example.com" /R /D Y
takeown /f "\\SERVER\SHARE\...\%NAME%"/R /D Y
takeown /f "\\SERVER\SHARE\%NAME%" /R /D Y
takeown /f "\\SERVER\SHARE\%NAME%" /R /D Y
takeown /f "\\SERVER\SHARE\...\%NAME%" /R /D Y
rmdir /s "\\SERVER\SHARE\%NAME%.example.com"
rmdir /s "\\SERVER\SHARE\...\%NAME%"
rmdir /s "\\SERVER\SHARE\%NAME%"
rmdir /s "\\SERVER\SHARE\%NAME%"
rmdir /s "\\SERVER\SHARE\...\%NAME%"
:END