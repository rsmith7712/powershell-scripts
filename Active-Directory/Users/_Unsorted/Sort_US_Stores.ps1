<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 03/23/2017
    Organization: Domain, Inc.
    Filename: Sort_US_Stores.ps1
    Description: [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]
    =========================================================
    .VERSION
        [ENTER CURRENT VERSION INFO]

    .VERSION INFO
        [ENTER PREVIOUS VERSION INFO]
#>

<# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format "HHmmss"
$Script:Logfile = "C:\temp\#filename_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "VALUE, VALUE"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}
#> # ----------------------------------------------------------------------------------------------
#Variables

$userpull = (Get-ADUser -SearchBase "ou=store users,ou=store accounts,dc=domain,dc=com" -filter *).userprincipalname
$stores = @("1","5","8")


# ----------------------------------------------------------------------------------------------
#Functions

# ----------------------------------------------------------------------------------------------
#Script

foreach($user in $userpull)
{
    $checkuser = $user.substring(0,7)
    $check = (Get-ADUser $checkuser).name

    if($check -like "*lab*")
    {
        continue
    }
    else
    {
        if($stores -contains $user.substring(0,1))
        {
            $user | Out-File C:\temp\US_Stores.csv -Append -NoClobber
        }
        else
        {
            continue
        }
    }
}