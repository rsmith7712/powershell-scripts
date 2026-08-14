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