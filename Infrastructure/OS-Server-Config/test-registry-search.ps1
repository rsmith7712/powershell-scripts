
Import-Module -Name ActiveDirectory
Get-ADComputer -Filter {OperatingSystem -Like "Windows *Server*"} | Select-Object -Expand Name |
ForEach-Object 
{
    If (Test-Connection $_ -Count 1 -Quiet)
    {
        $result = Invoke-Command -Computer $_ -ScriptBlock { Get-GPRegistryValue -Name McAfee -Key "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\McAfee\AVEngine\AVDatVersion=0x000025" -ea SilentlyContinue }
        $state = "AVEngine " + "not " * ($result -eq $null) + "current"
    } else {
        $state = "not reachable"
    }
    [PSCustomObject] @{computername = $_; state = $state}
}
