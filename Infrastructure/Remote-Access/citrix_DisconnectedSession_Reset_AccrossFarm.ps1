# citrix_DisconnectedSession_Reset_AccrossFarm.ps1
# 
# Git- admin7712, 2016-07-13
# 
# Contributors:
# @Paul (CitrixTips.com - 2/11/13), 
# 
# Purpose of Script:
# 1. Kill all DISCONNECTED sessions in the Citrix farm 
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

Get-XASession | Where{$_.State -eq “Disconnected”} | Stop-XASession