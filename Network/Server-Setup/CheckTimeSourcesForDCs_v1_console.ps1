<#
.FILENAME
    CheckTimeSourcesForDCs_v1_console.ps1

.SUMMARY
    This script queries all domain controllers and 
    queries what time server they are looking to.

.RESULTS
    Display on Console

.AUTHOR
    Richard Smith
    2018-04-19
    
#>

#Import Modules
Import-Module ActiveDirectory

#Create Variables
$DomainControllers =  Get-ADDomainController -Filter * | Select-Object -expand name

#Create ForEach Loop and display results via Console
foreach ($DomainController in $DomainControllers){

$TimeQuery = w32tm /query /computer:$DomainController /source #TimeQuery within forEach loop

Write-Host "------------------------------------"
Write-Host "Domain Controller: $DomainController";
Write-Host "Time Server: $TimeQuery";
Write-Host "------------------------------------"

}