<#
.SYNOPSIS
  Short & Informational
 
.DESCRIPTION
  More in depth information.

.EXAMPLE
  If this script can be called from the command line, show exampls here
  
.NOTES
  Version:        1.0
  Author:         Put Your Name Here
  Creation Date:  01/01/2001
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (01/01/2001)
  Purpose/Change: Initial Script Development
#>
# Initializations
#################################
$Script:ProductName = "" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "Inquire" #Maybe change to "SilentlyContinue" for Production.

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
    
# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit