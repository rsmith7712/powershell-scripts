<#
.FILENAME
    CheckTimeSourcesForDCs_v2_csv.ps1

.SUMMARY
    This script queries all domain controllers and 
    queries what time server they are looking to.

.RESULTS
    Export to CSV

.AUTHOR
    Richard Smith
    2018-04-19
    
#>

#Import Modules
Import-Module ActiveDirectory

#Create Variables
$DomainControllers =  Get-ADDomainController -Filter * | Select-Object -expand name

#Create the empty array that will eventually be the CSV file
$csvContents = @() 

#Create ForEach Loop, $TimeQuery, New Object, Add-Member, and Export to CSV
 foreach ($DomainController in $DomainControllers){

    #Create $TimeQuery variable
    $TimeQuery = w32tm /query /computer:$DomainController /source
    
    #Create an object to append to the array
    $row = New-Object System.Object

    #Create a property called User. This will be the User column
    $row | Add-Member -MemberType NoteProperty -Name "Domain Controller" -Value $DomainController

    #Create a property called UserID. This will be the UserID column 
    $row | Add-Member -MemberType NoteProperty -Name "Time Source" -Value $TimeQuery

    #Append the new data to the array
    $csvContents += $row

} $csvContents | Export-CSV -Path C:\temp\TimeSourcesFor_DCs_v2.csv