# LEGAL
<# LICENSE
    MIT License, Copyright 2001 Richard Smith

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
    SQLExpressRestart.ps1

.SYNOPSIS
  Script is used to restart SQLExpress services on a machine if the service fails.
 
.DESCRIPTION
  
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  01/01/2001
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Script is used to restart SQLExpress services on a machine if the service fails.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "SQLExpressRestart" #Fill this in. Do not put the "TEAM_" prefix
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

function restart_service
{
    Param(
        [parameter(Mandatory=$true,
        position=0)]
        $Service
    )

    $servicestatus = Get-Service -Name $Service
    if($($servicestatus.status) -eq "running")
    {
        Restart-Service -Name $Service -Force
        if($?)
        {
            return $true
        }
        else 
        {
            return $false
        }
    }
    elseif($($servicestatus.Status) -eq "stopped")
    {
        Start-Service -Name $Service 
        if($?)
        {
            return $true
        }
        else 
        {
            return $false
        }
    }
    else 
    {
        return "unexpected state"
    }
}
    
# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

$processes = Get-Process -Name "sqlservr"
if($processes -ne $null)
{
    $count = 0
    foreach($process in $processes)
    {
        if($($process.responding) -eq $false)
        {
            $count++
        }
    }
    if($count -gt 0)
    {
        Log_ToSplunk -Message "SQL Server process stopped on $ENV:COMPUTERNAME, attempting to restart service."
        $sqlrestart = restart_service -Service $sql 
        if($sqlrestart -eq $true)
        {
            Log_ToSplunk -Message "SQL Service successfully restarted on $ENV:COMPUTERNAME" -Status "Success"
        }
        elseif ($sqlrestart -eq $false) 
        {
            Log_ToSplunk -Message "SQL Service could not be restarted on $ENV:COMPUTERNAME" -Status "Fail"
        }
        else 
        {
            Log_ToSplunk -Message "SQL Service was in an unexpected state."
        }
    }
}

$sql = 'MSSQL$SQLEXPRESS'
$sqlstatus = Get-Service -Name $sql
if($($sqlstatus.Status) -eq "Stopped")
{
    Log_ToSplunk -Message "SQL Service stopped on $ENV:COMPUTERNAME, attempting to restart service."
    $sqlrestart = restart_service -Service $sql 
    if($sqlrestart -eq $true)
    {
        Log_ToSplunk -Message "SQL Service successfully restarted on $ENV:COMPUTERNAME" -Status "Success"
    }
    elseif ($sqlrestart -eq $false) 
    {
        Log_ToSplunk -Message "SQL Service could not be restarted on $ENV:COMPUTERNAME" -Status "Fail"
    }
    else 
    {
        Log_ToSplunk -Message "SQL Service was in an unexpected state."
    }
}

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit