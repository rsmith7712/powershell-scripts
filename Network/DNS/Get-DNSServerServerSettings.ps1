# LEGAL
<# LICENSE
    MIT License, Copyright 2019 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    Get-DNSServerServerSettings.ps1

.SYNOPSIS
 Get-DNSServerServerSettings.ps1
 
.DESCRIPTION
 Get-DNSServerServerSettings.ps1 reports the DNS search server settings for computer object pulled from AD.
 * Splunk logging currently commented out until this script is ready for production.


.EXAMPLE
  
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  5/1/2019
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (5/1/2019)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Get-DNSServerServerSettings.ps1 reports the DNS search server settings for computer object pulled from AD.
     * Splunk logging currently commented out until this script is ready for production.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "Get-DNSServerServerSettings"
$ErrorActionPreference = "SilentlyContinue"

Function Log_ToSplunk{
Param(
    [parameter(Mandatory=$true,
    Position=0)]
    [String]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    [String]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    [String]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
    [int]
    $ID = $Null
)

$product = "team_" + $Script:ProductName
$uri = "https://hecext.example.com:18443/services/collector/event"
$header = @{}
$header.add('Content-Type', 'application/json')
$header.add('Authorization', 'Splunk Application-Key-Here')
$body = @{
    sourcetype = 'domain:ps:log'
    host = $env:COMPUTERNAME
    event = @{
        message = $Message
        user = $env:USERNAME
        product = $Product
        type = $Type
        status = $Status
        id = $ID
    }
}
$body = $body | ConvertTo-Json
Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}#---------[END Log_ToSplunk]---------

# Local Logging
#################################
if(!(test-path "c:\logs")){Mkdir c:\logs}
$Script:Logfile = "C:\temp\$Script:ProductName" + "Log.txt"
$CsvFile = "C:\temp\DNSHostNameList.csv" 
Add-Content -Path $CsvFile -Value 'HostName,DNSSearchServerIP,NetworkCard'

Function Append-Log($message1, $message2)
{
    $thetime = Get-Date -Format g
    "$thetime`: $message1" | Out-File $Script:Logfile -Append
    Add-Content -Path $CsvFile -Value $message2
}
#---------[END Append-Log]---------
Function Get-DNSConfigTest($computerobject)
{
    "$host"
    Get-WmiObject -class win32_NetworkAdapterConfiguration -ComputerName $computerobject
}
Function Get-DNSConfig($computerobject)
{
    $wmiquery = Get-WmiObject -class win32_NetworkAdapterConfiguration -ComputerName $computerobject
    $wmiquery | Where-Object {$null -ne $_.IPAddress -and $_.DHCPEnabled -ne $True} |
    ForEach-Object{
                    Try
                    {
                        $dns = $_.DNSServerSearchOrder
                        $adapter = $_.Description
                        $output1 = "$computerobject | SearchServers:{$dns} | adapter:$adapter"
                        $output2 = "$computerobject,$dns,$adapter"
                        $status = "Success"
                    }
                        Catch
                        {
                            $output1 = "ERROR: Failed to obtain DNS server search settings on host:$computerobject'n Exception Message: $($_.Exception.Message)."
                            $status ="Fail"
                        }
                    Finally
                    {
                        Write-Host $output1 -ForegroundColor Yellow
                        Append-Log $output1 $output2
                        #Log_ToSplunk -Message $output -Status $status
                    }
                  }
}
#---------[END Get-DNSConfig]---------


####################################
# /////-----[Script Begin]-----\\\\\
####################################
#Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"
Append-Log -message "Script Starting."
$computers = @()
#$computers += "$env:COMPUTERNAME"
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store additional computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "ou=Register Computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "OU=Store Ticket Computer,OU=Store Computers,DC=DOMAIN,DC=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "OU=SLC Servers,OU=Store Servers,DC=DOMAIN,DC=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "OU=Distribution Center Computers,OU=Store Computers,DC=Domain,DC=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "OU=Core Servers,OU=Store Servers,DC=DOMAIN,DC=com" | where-object {$_.name.substring(0,1) -ne "3"}).name

foreach($computer in $computers)
{
    Get-DNSConfig -computerobject $($computer)
}
#Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Append-Log -message "Script Ending."
####################################
# \\\\\-----[Script End]------/////
####################################

