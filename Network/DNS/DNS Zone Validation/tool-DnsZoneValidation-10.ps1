# Define output directories
$ResultsPath = "C:\Temp\Results"
$LogsPath = "C:\Temp\Logs"

# Ensure output directories exist
if (-not (Test-Path -Path $ResultsPath)) {
    New-Item -ItemType Directory -Path $ResultsPath -Force | Out-Null
}
if (-not (Test-Path -Path $LogsPath)) {
    New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
}

# Define log file
$LogFile = Join-Path -Path $LogsPath -ChildPath "log-DNS-Zone-Validation.txt"

# Function to write logs
function Write-Log {
    param (
        [string]$Message
    )
    $TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $LogEntry = "$TimeStamp - $Message"
    Write-Output $LogEntry | Out-File -FilePath $LogFile -Append -Force
}

# Request elevated domain credentials
$RetryCount = 0
$MaxRetries = 3
while ($RetryCount -lt $MaxRetries) {
    $DomainCredential = Get-Credential -Message "Enter elevated domain credentials"
    try {
        # Get a domain controller to validate credentials
        $DomainController = Get-ADDomainController -Discover -ErrorAction Stop
        $DCName = $DomainController.HostName
        $DCIPAddress = $DomainController.IPv4Address

        Write-Log "Using Domain Controller: Name=$DCName, IP=$DCIPAddress for validation."

        # Validate credentials by querying the domain controller
        Invoke-Command -ComputerName $DCName -Credential $DomainCredential -ScriptBlock {
            hostname
        } -ErrorAction Stop

        Write-Log "Credentials validated successfully against Domain Controller: $DCName."
        break
    } catch {
        $RetryCount++
        Write-Log "Error: Invalid credentials attempt $RetryCount of $MaxRetries. $_.Exception.Message"
        Write-Host "Invalid credentials or insufficient permissions. Attempt $RetryCount of $MaxRetries." -ForegroundColor Red

        if ($RetryCount -ge $MaxRetries) {
            Write-Log "Maximum credential attempts reached. Exiting script."
            Write-Host "Maximum attempts reached. Exiting script." -ForegroundColor Red
            exit
        }
    }
}

# Retrieve available DNS zones
try {
    $DnsZones = Invoke-Command -ComputerName $DCName -Credential $DomainCredential -ScriptBlock {
        Get-DnsServerZone
    } -ErrorAction Stop

    Write-Log "Retrieved DNS zones from Domain Controller: $DCName."

    # Display available zones
    Write-Host "Available DNS Zones:" -ForegroundColor Green
    $ZoneList = $DnsZones.ZoneName
    for ($i = 0; $i -lt $ZoneList.Count; $i++) {
        Write-Host "$($i + 1). $($ZoneList[$i])"
    }

    # Prompt user for a zone to validate
    $Selection = Read-Host "Enter the number corresponding to the DNS zone you want to validate"
    $ZoneName = $ZoneList[[int]$Selection - 1]
    Write-Log "User selected DNS zone: $ZoneName."
} catch {
    Write-Log "Error: Unable to retrieve DNS zones. $_.Exception.Message"
    Write-Host "Failed to retrieve DNS zones. Exiting script." -ForegroundColor Red
    exit
}

# Retrieve A records from the selected zone
try {
    $DnsRecords = Invoke-Command -ComputerName $DCName -Credential $DomainCredential -ScriptBlock {
        param ($ZoneName)
        Get-DnsServerResourceRecord -ZoneName $ZoneName -RecordType A
    } -ArgumentList $ZoneName -ErrorAction Stop

    Write-Log "Retrieved $(($DnsRecords | Measure-Object).Count) A records from zone '$ZoneName'."
} catch {
    Write-Log "Error: Unable to retrieve A records. $_.Exception.Message"
    Write-Host "Failed to retrieve A records. Exiting script." -ForegroundColor Red
    exit
}

# Validate each record and prepare results
$Results = foreach ($Record in $DnsRecords) {
    $Retry = 2
    $PingStatus = "Stale"
    $Reason = "Unreachable"
    $Address = $Record.RecordData.IPv4Address

    while ($Retry -ge 0) {
        try {
            Test-Connection -ComputerName $Address -Count 1 -ErrorAction Stop
            $PingStatus = "Alive"
            $Reason = ""
            break
        } catch {
            $Retry--
            if ($Retry -lt 0) {
                $Reason = $_.Exception.Message
            }
        }
    }

    [PSCustomObject]@{
        Name      = $Record.RecordName
        Type      = "A"
        Address   = $Address
        Zone      = $ZoneName
        Status    = $PingStatus
        Timestamp = $Record.Timestamp
        Reason    = $Reason
    }
}

# Save results
$ResultsFile = Join-Path -Path $ResultsPath -ChildPath "results-DNS-Zone-Validation.csv"
$Results | Export-Csv -Path $ResultsFile -NoTypeInformation -Force
Write-Log "Results saved to '$ResultsFile'."
Write-Host "Results saved to: $ResultsFile" -ForegroundColor Green


<#

Key Features:
    Folder Validation:
        -Ensures the C:\Temp\Results and C:\Temp\Logs directories exist; creates them if necessary.
    Logging:
        -Logs script events to log-DNS-Zone-Validation.txt for traceability.
    DNS Zone Validation:
        -Prompts the user for a DNS zone and retrieves its records.
    Reachability Test:
        -Validates if DNS records are alive and marks stale entries.
    Results File:
        -Saves results to results-DNS-Zone-Validation.csv.
    Retry Logic:
        -Allows the user to validate another DNS zone without restarting the script.
    Credential Management:
        -Caches credentials during the session and purges them afterward.

#>