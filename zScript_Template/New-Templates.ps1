<#
.SYNOPSIS
  Short & Informational
 
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  06/28/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 
  Purpose/Change: Initial Script Development
#>
# Initializations
#################################
$Script:ProductName = "New-ConfigTemplates" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.

# Functions
#################################
function Log_ToSplunk
{
	[CmdletBinding()]
	Param
	(
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
	$body = $body | ConvertTo-Json

	$SB = {
		param($uri,$header,$body)
		Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
	}

	$job = Start-Job -scriptblock $SB -argumentlist @($uri,$header,$body)
	$timeout = 10
	Wait-Job $job -Timeout $timeout
	Stop-Job $job
	Receive-Job $job
	Remove-Job $job
}

function new_templates
{
  [CmdletBinding()]
  Param
  (
    [parameter(Mandatory=$true,
    Position=0)]
    $UFO_NUMBER,

    [parameter(Mandatory=$true,
    Position=1)]
    $SiteName,

    [parameter(Mandatory=$true,
    Position=2)]
    $SerialNode0,

    [parameter(Mandatory=$true,
    Position=3)]
    $SerialNode1
  )
  $secondoct = $UFO_NUMBER.Substring(0,2)
  $thirdoct = $UFO_NUMBER.substring(2,2)
  $thirdoct = $thirdoct.TrimStart("0")

  $lookuptable = @{
      'UFO_NUMBER' = "$UFO_NUMBER"
      'SITENAME' = "$sitename"
      'MEMBER0' = "$serialnode0"
      'MEMBER1' = "$serialnode1"
      'x.y' = ($secondoct + '.' + $thirdoct)
  }

  Get-Content -Path $script:MGROrig | ForEach-Object {
    $line = $_
  
    $lookuptable.GetEnumerator() | ForEach-Object {
        if ($line -match $_.key)
        {
            $line = $line -replace $_.Key, $_.Value
        }
    }
    $line
  } | Out-File $script:MGRNew -Force 
  Log_ToSplunk -Message "MGR config template created for $UFO_NUMBER" -Status "success"
  
  Get-Content -Path $script:REGOrig | ForEach-Object {
    $line = $_
  
    $lookuptable.GetEnumerator() | ForEach-Object {
        if ($line -match $_.key)
        {
            $line = $line -replace $_.Key, $_.Value
        }
    }
    $line
  } | Out-File $script:REGNew -Force 
  Log_ToSplunk -Message "REG config template created for $UFO_NUMBER" -Status "success"
}

# Variables
#################################

$UFO_NUMBER = Read-Host "Enter UFO_NUMBER"
$sitename = Read-Host "Enter Site Name | NO SPACES"
$serialnode0 = Read-Host "Enter Serial Number of Node0"
$serialnode1 = Read-Host "Enter Serial Number of Node1"

$script:MGROrig = "\\SERVER\SHARE\...\Config Templates\Meraki_Configs\MGR_Config_Template.txt"
$script:MGRNew = ("\\SERVER\SHARE\...\Config Templates\Meraki_Configs\Store_Templates\" + $UFO_NUMBER + "_MGR.txt")

$script:REGOrig = "\\SERVER\SHARE\...\Config Templates\Meraki_Configs\REG_Config_Template.txt"
$script:REGNew = ("\\SERVER\SHARE\...\Config Templates\Meraki_Configs\Store_Templates\" + $UFO_NUMBER + "_REG.txt")
    
# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

new_templates -UFO_NUMBER $UFO_NUMBER -SiteName $sitename -SerialNode0 $serialnode0 -SerialNode1 $serialnode1

Start-Process -FilePath 'C:\Program Files (x86)\Notepad++\notepad++.exe' -ArgumentList "$script:MGRNew"
Start-Process -FilePath 'C:\Program Files (x86)\Notepad++\notepad++.exe' -ArgumentList "$script:REGNew"

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit