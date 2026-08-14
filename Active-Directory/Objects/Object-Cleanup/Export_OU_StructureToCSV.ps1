<#

.CREATED-BY
    Brad_Voris

.SUMMARY
    I had a project where i needed to replicate the OU 
    structure in a dummy test domain for validation of 
    group policy objects (things like mapped drives/printers 
    for groups) I created this script to export  the OU 
    structure from our existing AD environment into my 
    lab environment.

    This can also be done with specific LDAP commands 
    but I wanted to learn how to do it in PowerShell.
 
    Hand script if you ever want to import a replica 
    of your OU structure in a lab environment

.FILENAME
    Export_OU_StructureToCSV.ps1

.WEBSITE
    https://gallery.technet.microsoft.com/scriptcenter/Export-OU-structure-to-CSV-63b12525
#>



Import-Module ActiveDirectory 
Get-ADOrganizationalUnit -filter * |
 Select Name,DistinguishedName |
  Export-csv -path C:\temp\AD_OU_Export.csv -NoTypeInformation