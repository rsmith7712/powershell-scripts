# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    CompleteViewServiceMonitor.ps1

.SYNOPSIS
  Script that runs via scheduled task.  Monitors CompleteView log files for error events.  Restarts services if errors are detected.
 
.DESCRIPTION
  More in depth information.
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  06/11/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    More in depth information.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "CompleteViewServiceMonitor" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.

# JSON Functions (For Powershell Versions 2 or 3)
# https://github.com/EliteLoser/ConvertTo-Json/blob/master/ConvertTo-STJson.ps1
#################################
function FormatString {
  param(
      [String] $String)
  $String -replace '\\', '\\' -replace '\n', '\n' `
      -replace '\u0008', '\b' -replace '\u000C', '\f' -replace '\r', '\r' `
      -replace '\t', '\t' -replace '"', '\"'
}
function GetNumberOrString {
  param(
      $InputObject)
  if ($InputObject -is [System.Byte] -or $InputObject -is [System.Int32] -or `
      ($env:PROCESSOR_ARCHITECTURE -imatch '^(?:amd64|ia64)$' -and $InputObject -is [System.Int64]) -or `
      $InputObject -is [System.Decimal] -or $InputObject -is [System.Double] -or `
      $InputObject -is [System.Single] -or $InputObject -is [long] -or `
      ($Script:CoerceNumberStrings -and $InputObject -match $Script:NumberRegex)) {
      "$InputObject"
  }
  else {
      """$(FormatString -String $InputObject)"""
  }
}

function ConvertToJsonInternal {
  param(
      $InputObject, # no type for a reason
      [Int32] $WhiteSpacePad = 0)
  [String] $Json = ""
  $Keys = @()
  if ($null -eq $InputObject) {
      $null
  }
  elseif ($InputObject -is [Bool] -and $InputObject -eq $true) {
      $true
  }
  elseif ($InputObject -is [Bool] -and $InputObject -eq $false) {
      $false
  }
  elseif ($InputObject -is [HashTable]) {
      $Keys = @($InputObject.Keys)
  }
  elseif ($InputObject.GetType().FullName -eq "System.Management.Automation.PSCustomObject") {
      $Keys = @(Get-Member -InputObject $InputObject -MemberType NoteProperty |
          Select-Object -ExpandProperty Name)
  }
  elseif ($InputObject.GetType().Name -match '\[\]|Array') {
      $Json += "[`n" + (($InputObject | ForEach-Object {
          if ($null -eq $_) {
              " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "null"
          }
          elseif ($_ -is [Bool] -and $_ -eq $true) {
              " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "true"
          }
          elseif ($_ -is [Bool] -and $_ -eq $false) {
              " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "false"
          }
          elseif ($_ -is [HashTable] -or $_.GetType().FullName -eq "System.Management.Automation.PSCustomObject" -or $_.GetType().Name -match '\[\]|Array') {
              " " * ((4 * ($WhiteSpacePad / 4)) + 4) + (ConvertToJsonInternal -InputObject $_ -WhiteSpacePad ($WhiteSpacePad + 4)) -replace '\s*,\s*$' #-replace '\ {4}]', ']'
          }
          else {
              $TempJsonString = GetNumberOrString -InputObject $_
              " " * ((4 * ($WhiteSpacePad / 4)) + 4) + $TempJsonString
          }
      }) -join ",`n") + "`n$(" " * (4 * ($WhiteSpacePad / 4)))],`n"
  }
  else {
      GetNumberOrString -InputObject $InputObject
  }
  if ($Keys.Count) {
      $Json += "{`n"
      foreach ($Key in $Keys) {
          if ($null -eq $InputObject.$Key) {
              $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": null,`n"
          }
          elseif ($InputObject.$Key -is [Bool] -and $InputObject.$Key -eq $true) {
              $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": true,`n"            }
          elseif ($InputObject.$Key -is [Bool] -and $InputObject.$Key -eq $false) {
              $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": false,`n"
          }
          elseif ($InputObject.$Key -is [HashTable] -or $InputObject.$Key.GetType().FullName -eq "System.Management.Automation.PSCustomObject") {
              $Json += " " * ($WhiteSpacePad + 4) + """$Key"":`n$(" " * ($WhiteSpacePad + 4))"
              $Json += ConvertToJsonInternal -InputObject $InputObject.$Key -WhiteSpacePad ($WhiteSpacePad + 4)
          }
          elseif ($InputObject.$Key.GetType().Name -match '\[\]|Array') {
              $Json += " " * ($WhiteSpacePad + 4) + """$Key"":`n$(" " * ((4 * ($WhiteSpacePad / 4)) + 4))[`n" + (($InputObject.$Key | ForEach-Object {
                  if ($null -eq $_) {
                      " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "null"
                  }
                  elseif ($_ -is [Bool] -and $_ -eq $true) {
                      " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "true"
                  }
                  elseif ($_ -is [Bool] -and $_ -eq $false) {
                      " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "false"
                  }
                  elseif ($_ -is [HashTable] -or $_.GetType().FullName -eq "System.Management.Automation.PSCustomObject" `
                      -or $_.GetType().Name -match '\[\]|Array') {
                      " " * ((4 * ($WhiteSpacePad / 4)) + 8) + (ConvertToJsonInternal -InputObject $_ -WhiteSpacePad ($WhiteSpacePad + 8)) -replace '\s*,\s*$'
                  }
                  else {
                      $TempJsonString = GetNumberOrString -InputObject $_
                      " " * ((4 * ($WhiteSpacePad / 4)) + 8) + $TempJsonString
                  }
              }) -join ",`n") + "`n$(" " * (4 * ($WhiteSpacePad / 4) + 4 ))],`n"
          }
          else {
              $TempJsonString = GetNumberOrString -InputObject $InputObject.$Key
              $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": $TempJsonString,`n"
          }
      }
      $Json = $Json -replace '\s*,$' # remove trailing comma that'll break syntax
      $Json += "`n" + " " * $WhiteSpacePad + "},`n"
  }
  $Json
}

function ConvertTo-STJson {
  [CmdletBinding()]
  param(
      [AllowNull()]
      [Parameter(Mandatory=$true,
                 ValueFromPipeline=$true,
                 ValueFromPipelineByPropertyName=$true)]
      $InputObject,
      [Switch] $Compress,
      [Switch] $CoerceNumberStrings = $false)
  begin{
      $JsonOutput = ""
      $Collection = @()
      [Bool] $Script:CoerceNumberStrings = $CoerceNumberStrings
      [String] $Script:NumberRegex = '^-?\d+(?:(?:\.\d+)?(?:e[+\-]?\d+)?)?$'
  }
  process {
      if ($_) {
          $Collection += $_
      }
  }
  end {
      if ($Collection.Count) {
          $JsonOutput = ConvertToJsonInternal -InputObject ($Collection | ForEach-Object { $_ })
      }
      else {
          $JsonOutput = ConvertToJsonInternal -InputObject $InputObject
      }
      if ($null -eq $JsonOutput) {
          return $null # becomes an empty string :/
      }
      elseif ($JsonOutput -is [Bool] -and $JsonOutput -eq $true) {
          [Bool] $true # doesn't preserve bool type :/ but works for comparisons against $true
      }
      elseif ($JsonOutput-is [Bool] -and $JsonOutput -eq $false) {
          [Bool] $false # doesn't preserve bool type :/ but works for comparisons against $false
      }
      elseif ($Compress) {
          (
              ($JsonOutput -split "\n" | Where-Object { $_ -match '\S' }) -join "`n" `
                  -replace '^\s*|\s*,\s*$' -replace '\ *\]\ *$', ']'
          ) -replace ( # these next lines compress ...
              '(?m)^\s*("(?:\\"|[^"])+"): ((?:"(?:\\"|[^"])+")|(?:null|true|false|(?:' + `
                  $Script:NumberRegex.Trim('^$') + `
                  ')))\s*(?<Comma>,)?\s*$'), "`${1}:`${2}`${Comma}`n" `
            -replace '(?m)^\s*|\s*\z|[\r\n]+'
      }
      else {
          ($JsonOutput -split "\n" | Where-Object { $_ -match '\S' }) -join "`n" `
              -replace '^\s*|\s*,\s*$' -replace '\ *\]\ *$', ']'
      }
  }
}

# Functions
#################################
function Log_ToSplunk{
    Param(
    [parameter(Mandatory=$true,
    Position=0)]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
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
    If($($PSVersionTable.PSVersion.Major) -gt 3){
        $body = $body | ConvertTo-Json
        Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
    }
    Else
    {
        $body = $body | ConvertTo-STJson
        $SB = { 
            param($body, $uri)
            $request = [System.Net.WebRequest]::Create($uri)
            $request.ContentType = "application/json"
            $request.Method = "POST"
            $request.Headers.Add('Authorization', 'Splunk Application-Key-Here')
            try
            {
                $requestStream = $request.GetRequestStream()
                $streamWriter = New-Object System.IO.StreamWriter($requestStream)
                $streamWriter.Write($body)
            }
            finally
            {
                if ($null -ne $streamWriter) { $streamWriter.Dispose() }
                if ($null -ne $requestStream) { $requestStream.Dispose() }
            }
        $res = $request.GetResponse()
    }

    $timeout = 30
    $job = Start-Job -ScriptBlock $SB -ArgumentList @($body, $uri)
    Wait-Job $job -Timeout $timeout
    Stop-Job $job
    Receive-Job $job
    Remove-Job $job
    }
}

function read_log
{
    if(!(Test-Path "C:\temp"))
    {
        New-Item -Path "C:\temp" -ItemType Directory -Force
    }
    Copy-Item -Path "C:\Program Files\CompleteView\Logs\MainServer.StretchManager.log" -Destination "C:\temp\MainServer.StretchManager.log" -Force
    $content = Get-Content -Path "C:\temp\MainServer.StretchManager.log" | Where-Object { $_.trim() -ne "" }
    [int]$latest = $content.count - 1
    $timestamp = $content[$latest].Substring(0,19).Trim()
    $status = $content[$latest].Substring(20,7).Trim()
    $message = $content[$latest].Substring(88).Trim()
    $latestlog = New-Object psobject -Property @{
        TimeStamp = $timestamp
        Status = $status
        Message = $message
    }
    #$latestlog | Export-Csv -Path $script:MasterLog -Append
    return $latestlog
}

function Send_EmailAlert
{
    $smtp = "smtpi.example.com"
    $to = "pctechnicians@example.com"
    #$cc = 
    $bcc = "servicedesk@example.com"
    $from = "CompleteView Service Alerts <completeviewservicealerts@example.com>"
    $subject = "CompleteView Service on $env:COMPUTERNAME is Not Running"
    $body = "Please transfer ticket to desktop support for remediation."  
    Send-MailMessage -SmtpServer $smtp -To $to -Bcc $bcc -From $from -Subject $subject -Body $body -BodyAsHtml
}

# Variables
#################################

$script:MasterLog = "C:\temp\CompleteViewServiceMonitor.csv"
if(!(Test-Path "C:\Logs"))
{
    New-Item -Path "C:\Logs" -ItemType Directory
}

#logfile initialization, creates initial entries.
if(!(Test-Path -Path $script:MasterLog))
{
    New-Item -Path $script:MasterLog -ItemType File -Force
    Add-Content -Path $script:MasterLog -Value "TimeStamp,Status,Message"
    $initialcontent = Get-Content "C:\temp\MainServer.StretchManager.log" | Where-Object { $_.trim() -ne "" }
    foreach($entry in $initialcontent)
    {
        $timestamp = $entry.Substring(0,19).Trim()
        $status = $entry.Substring(20,7).Trim()
        $message = $entry.Substring(88).Trim()
        Add-Content -Path $script:MasterLog -Value "$timestamp,$status,$message"
    }
}

$event = read_log

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

#$events = Import-Csv $script:MasterLog | Where-Object {($_.Remediated -eq "") -and ($_.Status -eq "Error")}
$logs = Import-Csv $script:MasterLog

$match = $false
foreach($log in $logs)
{
    if($log.TimeStamp -eq $event.TimeStamp)
    {
        $match = $true
    }
}

if(($match -eq $false) -and ($event.Status -eq "Error"))
{
    Log_ToSplunk -Message "Service issue detected on $env:COMPUTERNAME, attempting to restart service"
    Get-Service -Name "CompleteView Server" | Restart-Service -Force
    if($?)
    {
        Log_ToSplunk -Message "CompleteView Server restarted on $env:COMPUTERNAME" -Status "Success"
    }
    else 
    {
        Log_ToSplunk -Message "CompleteView Server could not be restarted on $env:COMPUTERNAME" -Status "Fail"
        Send_EmailAlert
    } 
    Add-Content -Path $script:MasterLog -Value "$($event.timestamp),$($event.status),$($event.message)"
}

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit