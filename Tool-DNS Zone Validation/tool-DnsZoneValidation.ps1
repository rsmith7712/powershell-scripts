# Define output directories
$ResultsPath = "C:\Temp\Results"
$LogsPath = "C:\Temp\Logs"

# Ensure output directories exist
if (-not (Test-Path -Path $ResultsPath)) {
    Write-Log "Creating results directory: $ResultsPath"
    New-Item -ItemType Directory -Path $ResultsPath -Force | Out-Null
}
if (-not (Test-Path -Path $LogsPath)) {
    Write-Log "Creating logs directory: $LogsPath"
    New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
}

# Define log file with unique timestamp
$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path -Path $LogsPath -ChildPath "log-DNS-Zone-Validation-$TimeStamp.txt"

# Function to write logs
function Write-Log {
    param (
        [string]$Message
    )
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$TimeStamp - $Message"
    Write-Output $LogEntry | Out-File -FilePath $LogFile -Append -Force
}

# Troubleshooting steps function
function Troubleshoot-DNSZone {
    param (
        [string]$ZoneName,
        [pscredential]$DomainCredential
    )

    Write-Log "Starting troubleshooting for DNS zone: $ZoneName."

    # Verify the zone name
    if (-not $ZoneName -or $ZoneName -eq "") {
        Write-Host "Zone name is invalid or empty. Please enter a valid zone name." -ForegroundColor Red
        Write-Log "Error: Zone name is empty or invalid."
        return $false
    }

    # Check DNS server connectivity
    Write-Log "Checking DNS server connectivity."
    try {
        $DnsTest = nslookup $ZoneName
        if ($DnsTest -match "server can\'t find") {
            Write-Log "Error: Zone '$ZoneName' does not resolve."
            Write-Host "The DNS zone '$ZoneName' does not resolve. Please verify the zone name." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Log "Error: Unable to perform nslookup for '$ZoneName'. $_.Exception.Message"
        Write-Host "Unable to connect to the DNS server or resolve the zone name." -ForegroundColor Red
        return $false
    }

    Write-Log "Troubleshooting for zone '$ZoneName' completed successfully."
    return $true
}

# Prompt for DNS Zone and Credentials
Write-Log "Script started."

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

# Query the domain controller for available DNS zones
try {
    # Retrieve DNS zones only from domain controllers
    $DomainController = Get-ADDomainController -Discover -ErrorAction Stop
    $DCName = $DomainController.HostName
    Write-Log "Querying DNS zones from Domain Controller: $DCName."

    $DnsZones = Invoke-Command -ComputerName $DCName -Credential $DomainCredential -ScriptBlock {
        Get-DnsServerZone
    } -ErrorAction Stop

    Write-Log "Retrieved list of DNS zones from the domain controller."

    # Display available zones
    Write-Host "Available DNS Forward Lookup Zones:" -ForegroundColor Green
    $ZoneList = $DnsZones.ZoneName
    for ($i = 0; $i -lt $ZoneList.Count; $i++) {
        Write-Host "$($i + 1). $($ZoneList[$i])"
    }

    # Prompt user to select a zone
    $Selection = Read-Host "Enter the number corresponding to the DNS zone you want to validate"
    $ZoneName = $ZoneList[[int]$Selection - 1]
    Write-Log "User selected DNS zone: $ZoneName."
} catch {
    Write-Log "Error: Unable to retrieve DNS zones. $_.Exception.Message"
    Write-Host "Failed to retrieve DNS zones. Exiting script." -ForegroundColor Red
    exit
}

# Verify the zone exists
try {
    $DnsZone = Invoke-Command -ComputerName $DCName -Credential $DomainCredential -ScriptBlock {
        param ($ZoneName)
        Get-DnsServerZone -Name $ZoneName
    } -ArgumentList $ZoneName -ErrorAction Stop

    Write-Log "DNS zone '$ZoneName' found."
} catch {
    Write-Log "Error: DNS zone '$ZoneName' not found. $_.Exception.Message"
    Write-Host "The DNS zone '$ZoneName' does not exist. Please try again." -ForegroundColor Red
    exit
}

# Get DNS records
$DnsRecords = Invoke-Command -ComputerName $DCName -Credential $DomainCredential -ScriptBlock {
    param ($ZoneName)
    Get-DnsServerResourceRecord -ZoneName $ZoneName
} -ArgumentList $ZoneName

Write-Log "Retrieved $(($DnsRecords | Measure-Object).Count) records from zone '$ZoneName'."

# Prepare results
$Results = foreach ($Record in $DnsRecords) {
    $RecordName = $Record.RecordName
    $RecordType = $Record.RecordType
    $RecordData = $Record.RecordData -join ", "
    $Timestamp = $Record.Timestamp

    try {
        # Test if the record is alive
        if ($RecordType -eq "A" -or $RecordType -eq "AAAA") {
            $Address = $Record.RecordData.IPv4Address -or $Record.RecordData.IPv6Address
            $PingResult = Test-Connection -ComputerName $Address -Count 1 -ErrorAction Stop
            [PSCustomObject]@{
                Name       = $RecordName
                Type       = $RecordType
                Data       = $RecordData
                Timestamp  = $Timestamp
                Address    = $Address
                Status     = "Alive"
            }
        } else {
            [PSCustomObject]@{
                Name       = $RecordName
                Type       = $RecordType
                Data       = $RecordData
                Timestamp  = $Timestamp
                Address    = "N/A"
                Status     = "Unsupported Record Type"
            }
        }
    } catch {
        [PSCustomObject]@{
            Name       = $RecordName
            Type       = $RecordType
            Data       = $RecordData
            Timestamp  = $Timestamp
            Address    = $Address
            Status     = "Stale"
        }
    }
}

# Generate unique results file with incrementing number
$NextFileNumber = 1
$ExistingFiles = Get-ChildItem -Path $ResultsPath -Filter "results-DNS-Zone-Validation-*.csv" | ForEach-Object { $_.BaseName -replace '\D', '' } | Sort-Object {[int]$_} -Descending
if ($ExistingFiles) { $NextFileNumber = [int]$ExistingFiles[0] + 1 }
$ResultsFile = Join-Path -Path $ResultsPath -ChildPath "results-DNS-Zone-Validation-$([string]::Format('{0:D4}', $NextFileNumber)).csv"

# Validate directory and write results
try {
    $Results | Export-Csv -Path $ResultsFile -NoTypeInformation -Force
    Write-Log "Results saved to '$ResultsFile'."
    Write-Host "Results saved successfully to: $ResultsFile" -ForegroundColor Green
} catch {
    Write-Log "Error: Failed to save results to '$ResultsFile'. $_.Exception.Message"
    Write-Host "Failed to save results. Error: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Clean up cached credentials
Write-Log "Script completed. Purging credentials."
$DomainCredential = $null
Write-Host "Script completed. Logs can be found at '$LogFile'."


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