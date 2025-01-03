


# Prompt user for input
$networkRange = Read-Host "Enter the IPv4 network range (e.g., 192.168.1.0/24)"
$targetMacAddress = Read-Host "Enter the MAC address to search for (e.g., 00-14-22-01-23-45)"

# Validate MAC address format
if (-not ($targetMacAddress -match "^([0-9A-Fa-f]{2}[-:]){5}([0-9A-Fa-f]{2})$")) {
    Write-Host "Invalid MAC address format. Please ensure it is in the format 00-14-22-01-23-45." -ForegroundColor Red
    exit
}

# Function to get the MAC address of a device by IP
function Get-MacAddressByIP {
    param (
        [string]$IPAddress
    )
    try {
        $arpEntry = arp -a | Select-String $IPAddress
        if ($arpEntry) {
            $macAddress = ($arpEntry -split '\s+')[1]
            return $macAddress
        }
        else {
            return $null
        }
    }
    catch {
        Write-Host "Error while fetching MAC address for $IPAddress." -ForegroundColor Red
        return $null
    }
}

# Function to resolve the hostname of a device by IP
function Get-HostnameByIP {
    param (
        [string]$IPAddress
    )
    try {
        $hostname = [System.Net.Dns]::GetHostEntry($IPAddress).HostName
        return $hostname
    }
    catch {
        return "Unknown"
    }
}

# Scan the network range
$ipAddresses = @()
$networkParts = $networkRange -split '/'
$baseIP = $networkParts[0]
$subnetMask = $networkParts[1]

if (-not $subnetMask) {
    Write-Host "Invalid network range format. Please use CIDR notation, e.g., 192.168.1.0/24." -ForegroundColor Red
    exit
}

$ipBase = ($baseIP -split '\.')[0..2] -join '.'
for ($i = 1; $i -lt 255; $i++) {
    $ipAddresses += "$ipBase.$i"
}

Write-Host "Scanning the network range: $networkRange" -ForegroundColor Yellow

# Search for the MAC address in the range
foreach ($ip in $ipAddresses) {
    $macAddress = Get-MacAddressByIP -IPAddress $ip
    if ($macAddress -and ($macAddress -ieq $targetMacAddress)) {
        $hostname = Get-HostnameByIP -IPAddress $ip
        Write-Host "Found matching MAC address at IP: $ip (Hostname: $hostname)" -ForegroundColor Green
        exit
    }
}

Write-Host "No matching MAC address found in the specified network range." -ForegroundColor Red
