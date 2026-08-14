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

# Functions
#################################
function Log_ToSplunk{

    Param(
    [parameter(Mandatory=$true,
    ParameterSetName="Product",
    Position=0)]
    [String[]]
    $Product,

    [parameter(Mandatory=$true,
    ParameterSetName="Message",
    Position=1)]
    [String[]]
    $Message,

    [parameter(Mandatory=$false,
    ParameterSetName="Type",
    Position=2)]
    [String[]]
    $Type = "Log",

    [parameter(Mandatory=$false,
    ParameterSetName="Status",
    Position=3)]
    [String[]]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    ParameterSetName="ID",
    Position=4)]
    [int[]]
    $ID = $Null
    )

    $product = "team_" + $product
    $uri = "https://hecext.example.com:18443/services/collector/event"
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.add('Authorization', 'Splunk Application-Key-Here') # Get new key from Duncan
    $body = @{
        sourcetype = 'domain:ps:log' # Get new source type from Duncan
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
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body
    }
    
# Script Starts
#################################
Log_ToSplunk -Product $Script:ProductName -Message "Script Starting." -Type "Begin" -Status "Informational"

# Script Ends
#################################
Log_ToSplunk -Product $Script:ProductName -Message "Script Ending." -Type "End" -Status "Informational"
Exit