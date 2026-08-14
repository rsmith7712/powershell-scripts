###############################################################
# User Archive Script
#
#Purpose:
#Used to archive old user folders. Automatically will take old
#user files based on date and move them to the archive server.
#Be careful on what time's are set, they should always be
#negative!
#
#Author: Mark Gevaert
#Date: 8/3/2016
#Modified:
################################################################




#General Variables
$dir = Get-ChildItem \\SERVER\SHARE | Select -Property Name
[string] $LogFile = ""
[string] $TransferLogFile = ""
[string] $TransferExport = "C:\temp\userarcdoctransfer.csv"
[string] $errFile = "C:\temp\userdoc_transfer.err"
[string] $sourceloc = "\\SERVER\SHARE\"
[string] $archiveloc = "\\srv\a-UserDocuments$\"
[string] $LogFile = "C:\temp\roboarcdoc.log"
[string] $errfile = "C:\temp\userarcdoc.err"
#Varibles to designate last time file was accessed or written to.
#Write time should always be lower then access time.
$accesstime = -90
$writetime = -365

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
    if ($name -ne $user.SamAccountName){ 
        #Order last access time
        $lat = Get-ChildItem -path $sourceloc$name -Recurse | Sort-Object LastAccessTime -Descending | Select-Object -First 1
        #if it has been accessed in the last 90 days
        If ($lat.LastAccessTime -lt (Get-Date).AddDays($accesstime)) {
            #Add to log
            [string] $TransferLogFile = $TransferLogFile + "$name, will be archived, "+ "$lat.LastAccessTime`n"
            #Add user to locations
            [string] $source = $sourceloc + $name
            [string] $archive = $archiveloc + $name
            #robocopy $source $archive `"/mov`",`"/LOG+:$LogFile`",`"/e`",`"/nfl`",`"/ndl`",`"/np`",`"/r:5`",`"/mt:4`",`"/b`"
            }
        else {
            If ($lat.LastWriteTime -lt (Get-Date).AddDays($writetime)) {
                #Add to log
                [string] $TransferLogFile = $TransferLogFile + "$name, will be archived, "+ "$lat.LastWriteTime`n"
                #Add user to locations
                [string] $source = $sourceloc + $name
                [string] $archive = $archiveloc + $name
                #robocopy $source $archive `"/mov`",`"/LOG+:$LogFile`",`"/e`",`"/nfl`",`"/ndl`",`"/np`",`"/r:5`",`"/mt:4`",`"/b`"
            }
        }
    }

}
#Create an error log from the session log.  Convert error codes to descriptions:
$ExitCode = Get-Content $LogFile | Where-Object {$_ -like "*ERROR*"}



#Export transfer log (route log)
$TransferLogFile | Out-File -filepath $TransferExport
$ExitCode | Out-File -filepath $errfile
