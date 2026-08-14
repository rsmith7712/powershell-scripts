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
    Set-DNSConfig.ps1

.SYNOPSIS
 Set-DNSConfig.ps1

.DESCRIPTION
 Configures DNS server search IP address settings locally relative to this script.

.EXAMPLE
  Set-DnsConfig -dns "0.0.0.0","0.0.0.0"

.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  04/12/2019
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (04/12/2019)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Configures DNS server search IP address settings locally relative to this script.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "Set-DNSConfig"
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
$Script:UID = [guid]::NewGuid()  
####################################
#  /////-----[Functions]-----\\\\\
####################################

# JSON Functions (For Powershell Versions 2 or 3)
# https://github.com/EliteLoser/ConvertTo-Json/blob/master/ConvertTo-STJson.ps1

Function FormatString {
  param(
      [String] $String)
  $String -replace '\\', '\\' -replace '\n', '\n' `
      -replace '\u0008', '\b' -replace '\u000C', '\f' -replace '\r', '\r' `
      -replace '\t', '\t' -replace '"', '\"'
}
Function GetNumberOrString {
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
Function ConvertToJsonInternal {
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
Function ConvertTo-STJson {
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

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Log_ToSplunk{
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
#---------[END Log_ToSplunk]---------

Function Append-Log($message)
{   
    if(!(test-path "c:\logs")){Mkdir c:\logs}
    $Script:Logfile = "C:\temp\$Script:ProductName" + "Log.txt"
    $thetime = Get-Date -Format g
    "$thetime`: $message" | Out-File $Script:Logfile -Append
}
#---------[END Append-Log]---------
Function Global:Set-DNSConfig($dns)
{
    $wmiquery = Get-WmiObject -class win32_NetworkAdapterConfiguration 
    $wmiquery | Where-Object {$null -ne $_.IPAddress -and $_.DHCPEnabled -ne $True} |
    ForEach-Object{
                    Try
                    {
                        $dnsold = $_.DNSServerSearchOrder
                        $adapter = $_.Description
                        $_.SetDNSServerSearchOrder($dns)
                        $check = Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter "Description='$([string]$adapter)'"
                            if([string]$check.DNSServerSearchOrder -eq $dns)
                            {
                                $output = "DNS server search settings have been updated on host:$env:COMPUTERNAME | adapter:$adapter.`n Old setting:{$dnsold}`n New setting:{$dns}"
                                $status = "Success"
                            }
                                else
                                {
                                    $output = "Failed to update DNS server search settings on host:$env:COMPUTERNAME | adapter:$adapter.`n Old setting:{$dnsold}"                 
                                    $status = "Fail"
                                }
                    }
                        Catch
                        {
                            $output = "Failed to update DNS server search settings on host:$env:COMPUTERNAME | adapter:$adapter.`n Old setting:{$dnsold}`n Exception Message: $($_.Exception.Message)."
                            $status ="Fail"
                        }
                    Finally
                    {
                        Write-Host $output -ForegroundColor Yellow
                        Append-Log $output
                        Log_ToSplunk -Message $output -Status $status
                    }
                  }
}
#---------[END Set-DNSConfig]---------

####################################
# /////-----[Script Begin]-----\\\\\
####################################

Log_ToSplunk -Message "Script Starting." -Type "Informational Begin" -Status "" -ID "$Script:UID"
Set-DnsConfig -dns "0.0.0.0","0.0.0.0"
Log_ToSplunk -Message "Script Ending." -Type "Informational End" -Status "" -ID "$Script:UID"

 ####################################
# \\\\\-----[Script End]------/////
####################################

    

