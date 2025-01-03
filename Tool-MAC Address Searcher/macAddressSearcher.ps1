# LEGAL
<# LICENSE
    MIT License, Copyright 2025 Richard Smith

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
    macAddressSearcher.ps1

.SYNOPSIS
    PowerShell script to prompt the user to input an IPv4 network range and a MAC
    address, then scans the network to identify the domain computer associated
    with the specified MAC address. Displays results to console.

.FUNCTIONALITY
    Prompts for Input:
        - IPv4 network range in CIDR notation (e.g., 192.168.1.0/24).
        - Target MAC address to search for.
    Validates the MAC Address Format.
    Scans the Network:
        - Iterates through IPs in the specified range.
        - Uses arp -a to check for MAC addresses.
    Matches and Displays Results:
        - Resolves and prints the hostname of the computer with the matching MAC
            address.
        - Displays a message if no matches are found.

.NOTES

#>

# Hide the script's code from displaying in the console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Prompt user for input
$networkRange = Read-Host "Enter the IPv4 network range (e.g., 192.168.1.0/24)"
$targetMacAddress = Read-Host "Enter the MAC address to search for (e.g., 00-14-22-01-23-45)"

# Validate MAC address format
if (-not ($targetMacAddress -match "^([0-9A-Fa-f]{2}[-:]){5}([0-9A-Fa-f]{2})$")) {
    Write-Host "Invalid MAC address format. Please ensure it is in the format 00-14-22-01-23-45." -ForegroundColor Red
    exit
}

# Function to calculate IP range from CIDR
function Get-IpRange {
    param ([string]$Cidr)
    $ipBase, $prefixLength = $Cidr -split '/'
    $ipBase = [IPAddress]$ipBase
    $prefixLength = [int]$prefixLength
    $totalHosts = [math]::Pow(2, (32 - $prefixLength)) - 2
    1..$totalHosts | ForEach-Object { $ipBase.Address + $_ -as [IPAddress] }
}

# Run `arp -a` once
$arpTable = arp -a

# Function to get the MAC address from ARP table
function Get-MacAddressByARP {
    param ([string]$IPAddress)
    $entry = $arpTable | Select-String $IPAddress
    if ($entry) {
        return ($entry -split '\s+')[1]
    }
    else {
        return $null
    }
}

# Scan the network range
Write-Host "Calculating IP range for: $networkRange" -ForegroundColor Yellow
$ipAddresses = Get-IpRange -Cidr $networkRange

Write-Host "Scanning the network range..." -ForegroundColor Yellow

# Parallel processing for performance
$results = $ipAddresses | ForEach-Object -Parallel {
    param ($ip, $targetMacAddress, $arpTable)
    $macAddress = $arpTable | Select-String $ip | ForEach-Object { ($_ -split '\s+')[1] }
    if ($macAddress -and ($macAddress -ieq $using:targetMacAddress)) {
        $hostname = try { [System.Net.Dns]::GetHostEntry($ip).HostName } catch { "Unknown" }
        [PSCustomObject]@{ IP = $ip; Hostname = $hostname; MAC = $macAddress }
    }
} -ArgumentList $targetMacAddress, $arpTable -ThrottleLimit 10

# Display results
if ($results) {
    foreach ($result in $results) {
        Write-Host "Found matching MAC address at IP: $($result.IP) (Hostname: $($result.Hostname))" -ForegroundColor Green
    }
}
else {
    Write-Host "No matching MAC address found in the specified network range." -ForegroundColor Red
}