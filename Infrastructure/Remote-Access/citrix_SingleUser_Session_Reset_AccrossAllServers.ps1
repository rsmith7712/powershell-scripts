# citrix_SingleUser_Session_Reset_AccrossAllServers.ps1
# 
# Git- admin7712, 2016-07-13
# 
# Contributors:
# @Paul (CitrixTips.com - 2/11/13), 
# 
# Purpose of Script:
# 1. Kill a single user’s sessions across multiple Citrix XA servers (v.6.5) 
# 
# ############################################# 
# 
# Current Issues:
# 1. 
# 
# ############################################# 
# 


Import-Module ActiveDirectory;

Add-PSSnapin Citrix;

Get-XASession | Where{$_.AccountName -eq “username”} | Stop-XASession;