#Get Mail Nameserver - getmns.bat

@echo off
if @%1==@ goto USAGE
echo set type=MX>mnscmd.txt
echo %1>>mnscmd.txt
echo exit>>mnscmd.txt
nslookup<mnscmd.txt>mnsresult.txt
type mnsresult.txt
del mnsresult.txt
goto END
:USAGE
echo usage:
echo %0 domainname.ext
:END
echo.