<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: AD_Store_Query.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\AD_Store_Query_$stamp.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Name, Email Address, Logon Name"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Variables

$stores = (Get-ADUser -Filter * -SearchBase "ou=store managers,ou=store accounts,dc=domain,dc=com").samaccountname

# ----------------------------------------------------------------------------------------------
# Script

foreach($store in $stores)
{
    if($store.substring(0,1) -eq "1")
    {
        $name = (Get-ADUser $store -Properties *).name
        $description = (Get-ADUser $store -Properties *).description
        $email = (Get-ADUser $store -Properties *).mail
        Append-Log "$name, $email, $store"
    }
    elseif($store.substring(0,1) -eq "5")
    {
        $name = (Get-ADUser $store -Properties *).name
        $description = (Get-ADUser $store -Properties *).description
        $email = (Get-ADUser $store -Properties *).userprincipalname
        Append-Log "$name, $email, $store"
    }
    elseif($store.substring(0,1) -eq "8")
    {
        $name = (Get-ADUser $store -Properties *).name
        $description = (Get-ADUser $store -Properties *).description
        $email = (Get-ADUser $store -Properties *).userprincipalname
        Append-Log "$name, $email, $store"
    }
    else
    {
        continue
    }
}
