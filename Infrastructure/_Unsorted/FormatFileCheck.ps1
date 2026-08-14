#################################################
# Script: Local Drive Check
#
# Purpose: Checks to see if there is anything
#          saved locally on the machine before
#          imaging and logs it
#
# Author: Mark Gevaert
# Date: 8/24/2016
# Date Modified:
# Modifier:
#################################################

#Remote to external computer
$computer = Read-Host -Prompt 'Enter the computer name'


#Variables
$drivelocation = "\\$computer\C$"
$logsaveloc = "\\SERVER\SHARE\...\$env:computername.log"

#Grab Local Files
$items = Get-ChildItem -Path $drivelocation -recurse | 
          ? { $_.PsIsContainer -and $_.FullName -notmatch 'Windows' -and $_.FullName -notmatch 'Program Files'`
            -and $_.FullName -notmatch 'Public'} | Select FullName

foreach ($d in $items){
    #Grabs full path
    $path = $d.Fullname
    #Grabs Owner without domain
    $domainown = Get-ACL "$path" | select Owner
    $domainown = $domainown.owner
    $parts = $domainown.split("\")
    $owner = echo $parts[1]
    #find user in AD to verify
    $user = Get-ADUser -LDAPFilter "(userPrincipalName=$owner@example.com)" -SearchScope Subtree -SearchBase "DC=domain,DC=com"
    #Do not include folders
    if ($owner -eq $user.SamAccountName){
        if (($path -ne "C:\Users\$owner\Documents\*") -and ($path -ne "C:\Users\$owner\Music\*") -and `
($path -ne "C:\Users\$owner\Videos\*") -and ($path -ne "C:\Users\$owner\Pictures\*") -and ($path -ne "C:\Users\Public\*")){
            $documents = $documents + $path + ", File found to be from an owner," + "$owner`n"
            }
        }
}

$documents | Out-File -filepath $logsaveloc