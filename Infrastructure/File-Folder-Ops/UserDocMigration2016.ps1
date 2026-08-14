###############################################################
# User Migration w/ AD Check
#
#Purpose:
#Used for SAN migration, checks to see if there is a valid user
#folder and migrates it to the correct location. Inactive users
#go to archive and active users migrate to SAN. This will be
#filtered based on access time and AD user presence
#
#Author: Mark Gevaert
#Date: 8/3/2016
#Modified:
################################################################




#General Variables
$dir = Get-ChildItem \\SERVER\SHARE | Select -Property Name
[string] $LogFile = ""
[string] $TransferLogFile = ""
[string] $TransferExport = "C:\temp\userdoctransfer.csv"
[string] $errFile = "C:\temp\userdoc_transfer.err"
[string] $sourceloc = "\\SERVER\SHARE\"
[string] $activeloc = "\\SERVER\SHARE\"
[string] $archiveloc = "\\srv\a-UserDocuments$\"
[string] $LogFile = "C:\temp\robodoc.log"
[string] $errfile = "C:\temp\userdoc.err"

#Clean up Old Items
remove-item $errFile -force
remove-item $TransferExport -force
remove-item $LogFile -force

#Time to check folders
foreach ($d in $dir){
    #convert Folder result into simple name
    [string]$name = $d.name
    #find user in AD
    $user = Get-ADUser -LDAPFilter "(userPrincipalName=$name@example.com)" -SearchScope Subtree -SearchBase "DC=domain,DC=com"
    #check to see if user folder matches existing user
    if ($name -eq $user.SamAccountName){
        [string] $TransferLogFile = $TransferLogFile + "$name, will be transferred, existing user`n"
        [string] $source = $sourceloc + $name
        [string] $active = $activeloc + $name
        robocopy $source $active `"/copy:DATOU`",`"/LOG+:$LogFile`",`"/e`",`"/purge`",`"/nfl`",`"/ndl`",`"/np`",`"/r:5`",`"/mt:4`",`"/b`"
        }
        
     else {
        #Check last Access Time
        #$name = "coryh"
        $lat = Get-ChildItem -path $sourceloc$name -Recurse | Sort-Object LastAccessTime -Descending | Select-Object -First 1
        #if it has been accessed in the last 90 days
        If ($lat.LastAccessTime -gt (Get-Date).AddDays(-90)) {
            #Add to log
            [string] $TransferLogFile = $TransferLogFile + "$name, will be transferred, recently has been accessed, "+ "$lat.LastAccessTime`n"
            #Add user to locations
            [string] $source = $sourceloc + $name
            [string] $active = $activeloc + $name
            robocopy $source $active `"/copy:DATOU`",`"/LOG+:$LogFile`",`"/e`",`"/purge`",`"/nfl`",`"/ndl`",`"/np`",`"/r:5`",`"/mt:4`",`"/b`"
            }
        else {
            #Add to log
            [string] $TransferLogFile = $TransferLogFile + "$name, will not be transferred, no recent access, "+ "$lat.LastAccessTime`n"
            #Add user to locations
            [string] $source = $sourceloc + $name
            [string] $archive = $archiveloc + $name
            robocopy $source $archive `"/copy:DATOU`",`"/LOG+:$LogFile`",`"/e`",`"/purge`",`"/nfl`",`"/ndl`",`"/np`",`"/r:5`",`"/mt:4`",`"/b`"
            }
    }
}

#Create an error log from the session log.  Convert error codes to descriptions:
$ExitCode = Get-Content $LogFile | Where-Object {$_ -like "*ERROR*"}



#Export transfer log (route log)
$TransferLogFile | Out-File -filepath $TransferExport
$ExitCode | Out-File -filepath $errfile
