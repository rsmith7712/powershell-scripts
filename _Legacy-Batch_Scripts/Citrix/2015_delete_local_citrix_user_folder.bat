@echo off
title Purge Citrix User Folder
:mainmenu
cls
set user=
set /p user=Enter AD username:

for /l %%x in (1, 1, 20) do (
	net use z: /delete
	net use z: \\<SERVER>%%x\c$
	rmdir /S /Q "z:\Users\%user%"
	echo "Folder created on <SERVER>%%x"
)

echo Citrix User Folder Purge will now exit... Goodbye
pause>nul
exit
:end