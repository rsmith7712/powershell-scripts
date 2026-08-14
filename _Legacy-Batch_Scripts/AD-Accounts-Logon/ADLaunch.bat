set /p NAME=What is your Admin Logon? 
runas /profile /env /user:example.com\%NAME% "mmc %windir%\system32\dsa.msc"
