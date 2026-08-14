# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Get-WastedInfectionStatus.ps1

.DESCRIPTION
    Reports the wasted-file infection status across selected parts of the estate (corporate/retail servers, computers and tags) with timing.

.FUNCTIONALITY
    Reports wasted-file infection status.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

param
(   
    [switch]$CorpServers,
    [switch]$DomainControllers,
    [switch]$CorpComputers,
    [switch]$RetailServers,
    [switch]$RetailComputers,
    [switch]$Tag,
    [switch]$Reg
)
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
$currentDateTime = (Get-Date -Format o | ForEach-Object {$_ -replace ":", "."}).split("T")
$currentTime = ($currentDateTime[1]).split(".")
$timeStamp = "$($currentDateTime[0])_$($currentTime[0]).$($currentTime[1])"
$outfile = "\\SERVER\SHARE\...\wastedStatus_$($timestamp).csv"
if(Test-Path $outfile){Remove-Item $outfile -Force}

$computers = $null
$computers = @()
if ($RetailComputers)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store Computers Windows 10,OU=Store Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store Jumpstart Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Distribution Center Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store DVRs,OU=Store Computers,DC=DOMAIN,DC=com").name
}
if($RetailServers)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Core Servers,OU=Store Servers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=SLC Servers,OU=Store Servers,DC=DOMAIN,DC=com").name
}
if ($Tag)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store Ticket Computer,OU=Store Computers,DC=DOMAIN,DC=com").name
}
if ($Reg)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Store Register Computers,OU=Store Computers,DC=DOMAIN,DC=com").name
}
if ($CorpComputers)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Corporate Laptops,OU=Corporate Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Corporate Desktops,OU=Corporate Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Corporate View Desktops,OU=Corporate Computers,DC=DOMAIN,DC=com").name
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Partner Desktops,OU=Partner Computers,DC=DOMAIN,DC=com").name
}
if($CorpServers)
{
    $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Domain Servers,DC=DOMAIN,DC=com").name
}
if($DomainControllers)
{
     $computers += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "OU=Domain Controllers,DC=DOMAIN,DC=com").name
}
<#
$src = @()
$src = "reg.txt","tag.txt","dvr.txt","st.txt","w0.txt","js.txt","corp.txt"
$src | ForEach-Object{
    $rolesrc = $_
    $role = $rolesrc.split(".")[0]
#>
    $computers = Get-Content "\\SERVER\SHARE\...\cleanthese.txt"
    "ComputerName,Volume,totalWastedFound,totalWastedDeleted,totalWastedRemaining" | Out-File $outfile -Append ascii
    $computers | ForEach-Object{
        [string]$computer = $_
        Write-Output "[STATUS] : Checking online status for $computer."
        if(Test-Connection -ComputerName $computer -Count 1 -Quiet)
        {
            Write-Output "[STATUS] : $computer`: Confirmed host is online. Continuing operation."
            if (Test-Path "\\$computer\c$\...\wastedTotals.csv")
            {
                Write-Host "$computer - FOUND" -ForegroundColor Green
                type "\\$computer\c$\...\wastedTotals.csv" | Out-File $outfile -Append ascii
            }
        }
        else 
            {
                Write-Output "[ERROR] : $computer : Offline. $computer is unavailable. Cannot continue with $computer." 
            }
    #}
}
$elapsed = [math]::Round($stopwatch.Elapsed.TotalMinutes,2)
$stopwatch.Stop()
Write-Output "[STATUS] : Script Completion.TTC = $($elapsed) Minutes."
Exit
####################[SCRIPT ENDS]#####################

