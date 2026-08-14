<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 03/17/2017
    Organization: Domain, Inc.
    Filename: Store_outreach_compare.ps1
    Description: Creates a CSV that maps the store accounts to their corresponding outreach account. 
    =========================================================
    .VERSION
        [ENTER CURRENT VERSION INFO]

    .VERSION INFO
        [ENTER PREVIOUS VERSION INFO]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format "HHmmss"
$Script:Logfile = "C:\temp\Outreach_store_compare.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Store account, Outreach account"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}
# ----------------------------------------------------------------------------------------------
#Variables

$stores = Get-ADUser -SearchBase "ou=store users, ou=store accounts, dc=domain, dc=com" -Filter *
$outreachaccts = Get-ADUser -SearchBase "ou=storeoutreach, ou=service accounts, ou=domain services, dc=domain, dc=com" -Filter *

# ----------------------------------------------------------------------------------------------
#Script

foreach($store in $stores)
{
    foreach($outreach in $outreachaccts)
    {
        if($store.surname -eq $outreach.givenname)
        {
            Append-Log "$store, $outreach"
            continue
        }
        else
        {
            Append-log "$store, NO MATCH"
        }
    }
}