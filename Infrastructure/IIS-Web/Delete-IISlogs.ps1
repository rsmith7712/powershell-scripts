# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the ìSoftwareî),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED ìAS ISî, WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Delete-IISlogs.ps1.txt

.SYNOPSIS
Delete IIS log files from remote server

.DESCRIPTION
The script retrieves the location of IIS logs for all websites on a remote server and deletes those older than $Days days.

.PARAMETER Days
Specifies the number of days‚Äô worth of IIS logs to keep on the server

.EXAMPLE
Deletes IIS logs older than 28 days from all servers manually specified within the script's $excServers array
.\Delete-IISlogs.ps1 -Days 28


.NOTES
Name:     Delete-IISlogs.ps1
Author:   Nuno Mota
Modified: Richard Smith

.LINK
https://letsexchange.blogspot.com
https://gallery.technet.microsoft.com/Delete-IIS-Logs-Remotely-9d269a30

.FUNCTIONALITY
    The script retrieves the location of IIS logs for all websites on a remote server and deletes those older than $Days days.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#################################################################
# Variables and Functions
#################################################################

[CmdletBinding()]
Param (
 [Parameter(Position = 0, Mandatory = $False)]
 [Int] $Days = 28
)


Function Write-Log {
 [CmdletBinding()]
 Param ([String] $Type, [String] $Message)

 # Create a log file in the same location as the script containing all the actions taken
 $Logfile = $PSScriptRoot + "\Delete-IISlogs_Log_$(Get-Date -f 'yyyyMMdd').txt"
 If (!(Test-Path $Logfile)) {New-Item $Logfile -Force -ItemType File | Out-Null}

 $timeStamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
 "$timeStamp $Type $Message" | Out-File -FilePath $Logfile -Append
 
 Write-Verbose $Message
}

#################################################################
# Script Start
#################################################################

## Static Target Servers Listed By example.com (PROD, UAT), then Domain.ENG (DEV, QA) ##

[Array] $excServers = @("PD5-DM-IIS01",`
"PD5-DM-IIS02","PD5-DM-IIS03","PD5-DM-IIS04","PD5-DM-IIS05","PD5-DM-IIS06","PD5-DM-IIS07","PD5-DM-IIS08",`
"PD5-TRK-APP01","PS5-SAV-IIS01",`
"UD5-DM-IIS01","UD5-DM-IIS02","UD5-DM-IIS03","UD5-DM-IIS04","UD5-DM-IIS05","UD5-DM-IIS06","UD5-DM-IIS07","UD5-DM-IIS08",`
"UD5-TRK-APP01","US0-INT-IIS1",`
"DD5-DM-IIS01.domain.eng","DD5-DM-IIS02.domain.eng","DD5-DM-IIS03.domain.eng","DD5-DM-IIS04.domain.eng",`
"DD5-DM-IIS05.domain.eng","DD5-DM-IIS06.domain.eng","DD5-DM-IIS07.domain.eng","DD5-DM-IIS08.domain.eng",`
"DD5-TRK-APP01.domain.eng",`
"QD5-DM-IIS01.domain.eng","QD5-DM-IIS02.domain.eng","QD5-DM-IIS03.domain.eng","QD5-DM-IIS04.domain.eng",`
"QD5-DM-IIS05.domain.eng","QD5-DM-IIS06.domain.eng","QD5-DM-IIS07.domain.eng","QD5-DM-IIS08.domain.eng",`
"QD5-TRK-APP01.domain.eng")

ForEach ($server in $excServers) {
 Write-Log -Type "INF" -Message "Processing $server"
 
 If (Test-Connection -ComputerName $server -BufferSize 16 -Count 1 -ErrorAction 0 -Quiet) {
  Try {
   $countDel = Invoke-Command -ComputerName $server -ArgumentList $Days, $server -ScriptBlock {
    param($Days, $server)
    
    [Int] $countDel = 0
    Import-Module WebAdministration
    ForEach($webSite in $(Get-WebSite)) {
        $dir = "$($webSite.logFile.directory)\W3SVC$($webSite.ID)".Replace("%SystemDrive%", $env:SystemDrive)
     
     Write-Host "Checking IIS logs in $dir on $server" -ForegroundColor Green
     Get-ChildItem -Path $dir -Recurse | ? {$_.LastWriteTime -lt (Get-Date).addDays(-$Days)} | ForEach {
      Write-Host "Deleting", $_.FullName
      del $_.FullName -Confirm:$False
      $countDel++
     }
    }
    
    Return $countDel
   }
   
   Write-Log -Type "INF" -Message "Deleted $countDel logs from server $server"
  } Catch {
   Write-Log -Type "ERR" -Message "Unable to connect to $($server): $($_.Exception.Message)"
   Send-MailMessage -From "IISLogTruncation@example.comù -To "admin2@example.com" -Subject "ERROR ì Delete IIS Logs" -Body "Unable to connect to $($server): $($_.Exception.Message)" -SmtpServer smtpi.example.com -Priority "High"
  }
 } Else {
  Write-Log -Type "ERR" -Message "Unable to connect to $server"
  Send-MailMessage -From "IISLogTruncation@example.comù -To "admin2@example.com" -Subject "ERROR ì Delete IIS Logs" -Body "Unable to connect to $server" -SmtpServer smtpi.example.com -Priority "High"
 }
}