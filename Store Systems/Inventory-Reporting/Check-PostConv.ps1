# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    Check-PostConv.ps1

.SYNOPSIS
  Allows a PM to check store status.
 
.DESCRIPTION
  Does Stuf.
  
.NOTES
  Version:        1.1
  Author:         user26
  Creation Date:  04/19/18
  Purpose/Change: Streamlined by adding -AsJob.

.HISTORY
  Version:        1.0
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Does Stuf.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Clear-Host
Do {
    If($Count -ge 1){
        Clear-Host
        Write-Host "You've entered an invalid UFO_NUMBER. Try Again.`n" -ForegroundColor Red
        }
    $Store = Read-Host "What Store Are You Checking?"
    $Test = [RegEx]::IsMatch($Store,"^\d{4}$")
    If($Test -eq $True -and ([string]$Store).Substring(1,1) -le 2){$Continue = $True} #Validates the UFO_NUMBER is 4 digits and the 2nd digit is no greater than 2.
    $Count ++
    }
While($Continue -ne $True)

$TimeStamp = Get-Date -Format "HHmm"
$LogFile = "$($ENV:USERPROFILE)\Desktop\LogFiles\Store$Store.Time$TimeStamp.csv"
Add-Content $LogFile "HostName,Status,IP Address"

$StoreData = Import-CSV "\\SERVER\SHARE\...\NetworkConversionReport-$Store.csv"

$Hosts = $StoreData | Where-Object{$_.Status -ne "Offline"}
$Hosts = $Hosts.NewIPAddress
$Job = Test-Connection $Hosts -Count 4 -AsJob

Wait-Job $Job | Out-Null

$Results = Receive-Job $Job
ForEach($Device in $StoreData){
    $JobResults = $Results | Where-Object{$Device.NewIPAddress -eq $_.Address}
    If(($JobResults.StatusCode -ne 0).Count -gt 3){
        Add-Content $LogFile "$($Device.HostName),Offline,$($Device.NewIPAddress)"
        Write-Host "$($Device.HostName) is Unreachable at $($Device.NewIPAddress)." -ForegroundColor Red
    }
    Else{
        Add-Content $LogFile "$($Device.HostName),Online,$($Device.NewIPAddress)"
        Write-Host "$($Device.HostName) is Online at $($Device.NewIPAddress)." -ForegroundColor Green
    }
    
}
Start-Sleep 5
Write-Host ""
Write-Host "Opening Report CSV."
Invoke-Item $LogFile
Write-Host 'Press any key to exit...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
Exit