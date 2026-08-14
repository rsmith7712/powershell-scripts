#Author: user22
#Date: 7/22/2016
#Use: Disables autostart and loaduserprofile attributes for the DefaultAppPool in IIS Services.
#Note: PS Tools is required to run this script.


$computer = read-host "Enter Computer Name"

psexec \\$computer C:\windows\system32\inetsrv\appcmd.exe stop apppool DefaultAppPool

psexec \\$computer C:\Windows\System32\inetsrv\appcmd.exe set config -section:applicationpools /"[name='DefaultAppPool'].autostart:false"

psexec \\$computer C:\Windows\System32\inetsrv\appcmd.exe set config -section:applicationpools /"[name='DefaultAppPool'].processmodel.loadUserProfile:false"

psexec \\$computer C:\windows\system32\inetsrv\appcmd.exe start apppool DefaultAppPool