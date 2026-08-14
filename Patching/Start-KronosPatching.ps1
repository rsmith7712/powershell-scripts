# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Start-KronosPatching.ps1

.SYNOPSIS
  Script will automate the patching process of the Kronos environment.
 
.DESCRIPTION
  Babysits the Kronos environment through patching.
 
.NOTES
  Version:        0.2
  Author:         user26
  Creation Date:  09/25/2017
  Purpose/Change: Fleshing out Functions

.HISTORY
  Version:        0.1 (09/25/2017)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Babysits the Kronos environment through patching.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$Script:vCenter = "DOMAINVC1"
Connect-VIServer $Script:vCenter

Function Get-Uptime($Computer) #https://gallery.technet.microsoft.com/scriptcenter/Get-Uptime-PowerShell-eb98896f
{
try {
    $hostdns = [System.Net.DNS]::GetHostEntry($Computer)
    $OS = Get-WmiObject win32_operatingsystem -ComputerName $Computer -ErrorAction Stop
    $BootTime = $OS.ConvertToDateTime($OS.LastBootUpTime)
    $Uptime = $OS.ConvertToDateTime($OS.LocalDateTime) - $boottime
    $propHash = [ordered]@{
        ComputerName = $Computer
        BootTime     = $BootTime
        Uptime       = $Uptime
        }
    $objComputerUptime = New-Object PSOBject -Property $propHash
    Return $objComputerUptime
    } 
catch [Exception] {
    Write-Output "$computer $($_.Exception.Message)"
    Return $False
    }
}

Function Validate-Patches($Server)
{
    #Validate that patches are installed and the machine is ready to reboot/shutdown.
}

Function Install-Patches($Server) # https://4sysops.com/archives/install-and-schedule-windows-updates-with-powershell/
{
    Invoke-Command -ComputerName $Server -ScriptBlock{
        $Criteria = "IsInstalled=0 and Type='Software'"
        $Searcher = New-Object -ComObject Microsoft.Update.Searcher
        $SearchResult = $Searcher.Search($Criteria).Updates
        $Session = New-Object -ComObject Microsoft.Update.Session
        $Downloader = $Session.CreateUpdateDownloader()
        $Downloader.Updates = $SearchResult
        $Downloader.Download()
        $Installer = New-Object -ComObject Microsoft.Update.Installer
        $Installer.Updates = $SearchResult
        $Result = $Installer.Install()
        If ($Result.rebootRequired) { Stop-Computer -Force }
        Else {Stop-Computer -Force} # We need to shut it down no matter what.
    }
}

Function Validate-Services($Server,$Services)
{
    ForEach($Service in $Services)
    {
        $Query = Get-Service -CN $Server -Name $Service
        If($($Query.Status) -ne "Running")
        {
            Get-Service -CN $Server -Name $Service | Start-Service
            Start-Sleep 5
            $ReQuery = Get-Service -CN $Server -Name $Service
            If($($ReQuery.Status) -ne "Running")
            {
                Return $False
            }
        }
        Return $True
    }
}

Function Boot-VM($VM)
{
    #Boot VM through PowerCLI and do not prompt for confirmation
    Start-VM -VM $VM -Confirm $false
}

Function Wait-ForStart($Server)
{
    Do
    {
        Start-Sleep 30
        $Up = Get-Uptime $Server
    }
    While($($Up.Uptime.TotalHours) -gt 1)
}

#Validate Patches have installed on "srv" and then SHUTDOWN the server.

#Validate Patches have installed on "srv" and then SHUTDOWN the server.

#Validate Patches have installed on "srv" and then SHUTDOWN the server.

#Validate Patches have installed on "srv" and then SHUTDOWN the server.

#Validate Patches have installed on "srv" and then SHUTDOWN the server.

#Validate Patches have installed on "srv" and then REBOOT the server.

#Validate Services are up on "srv" and then boot "srv.example.com" via PowerCLI
Wait-ForStart "srv"
$Start1 = Validate-Services "srv" "Service1,Service2"
If($Start1 -eq $False)
{
    #Prompt for user intervention
}
Boot-VM "srv.example.com"
#Validate Services are up on "srv" and then boot "srv.example.com" via PowerCLI
Wait-ForStart "srv"
$Start2 = Validate-Services "srv" "Service1,Service2"
If($Start2 -eq $False)
{
    #Prompt for user intervention
}
Boot-VM "srv.example.com"
#Validate Services are up on "srv" and then boot "srv.example.com" via PowerCLI
Wait-ForStart "srv"
$Start3 = Validate-Services "srv" "Service1,Service2"
If($Start3 -eq $False)
{
    #Prompt for user intervention
}
Boot-VM "srv.example.com"
#Validate Services are up on "srv" and then boot "srv.example.com" via PowerCLI
Wait-ForStart "srv"
$Start4 = Validate-Services "srv" "Service1,Service2"
If($Start4 -eq $False)
{
    #Prompt for user intervention
}
Boot-VM "srv.example.com"
#Validate Services are up on "srv" and then boot "srv.example.com" via PowerCLI
Wait-ForStart "srv"
$Start5 = Validate-Services "srv" "Service1,Service2"
If($Start5 -eq $False)
{
    #Prompt for user intervention
}
Boot-VM "srv.example.com"
#Validate Services are up on "srv" and open windows to both srv and srv for user to validate functionality.
Wait-ForStart "srv"
$Start5 = Validate-Services "srv" "Service1,Service2"
If($Start5 -eq $False)
{
    #Prompt for user intervention
}
