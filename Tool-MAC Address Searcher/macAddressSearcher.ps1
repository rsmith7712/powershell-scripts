﻿# LEGAL
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
    See location for notes and history:
    https://github.com/rsmith7712 
        PowerShell - Tool-MAC Address Searcher
#>

# Hide the script's code from displaying in the console
# Removed setting OutputEncoding to avoid invalid handle error

# Define log directory and ensure it exists
$logDir = "C:\Temp\Logs\MACSearch"
if (-not (Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Create a unique log file for this search
$timestamp = (Get-Date -Format "yyyy-MM-dd-HH-mm-ss")
$logFile = "$logDir\log-MACsearch-$timestamp.txt"

# Function to log messages
function Log-Message {
    param (
        [string]$Message
    )
    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timestamp] $Message"
    $logEntry | Out-File -FilePath $logFile -Append
    Write-Host $Message
}

# Record the start time
$startTime = Get-Date
Log-Message "Search initiated. Network range: $networkRange, Target MAC address: $targetMacAddress"

# Prompt user for input
$networkRange = Read-Host "Enter the IPv4 network range (e.g., 192.168.1.0/24)"
$targetMacAddress = Read-Host "Enter the MAC address to search for (e.g., 00-14-22-01-23-45)"

# Validate MAC address format
if (-not ($targetMacAddress -match "^([0-9A-Fa-f]{2}[-:]){5}([0-9A-Fa-f]{2})$")) {
    $errorMsg = "Invalid MAC address format. Please ensure it is in the format 00-14-22-01-23-45."
    Log-Message $errorMsg
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
        $errorMsg = "Error while fetching MAC address for $IPAddress."
        Log-Message $errorMsg
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
    $errorMsg = "Invalid network range format. Please use CIDR notation, e.g., 192.168.1.0/24."
    Log-Message $errorMsg
    exit
}

$ipBase = ($baseIP -split '\.')[0..2] -join '.'
for ($i = 1; $i -lt 255; $i++) {
    $ipAddresses += "$ipBase.$i"
}

Log-Message "Scanning the network range: $networkRange"

# Search for the MAC address in the range
foreach ($ip in $ipAddresses) {
    $macAddress = Get-MacAddressByIP -IPAddress $ip
    if ($macAddress -and ($macAddress -ieq $targetMacAddress)) {
        $hostname = Get-HostnameByIP -IPAddress $ip
        $successMsg = "Found matching MAC address at IP: $ip (Hostname: $hostname)"
        Log-Message $successMsg
        # Calculate and log total execution time
        $endTime = Get-Date
        $executionTime = $endTime - $startTime
        $executionMsg = "Total execution time: $executionTime"
        Log-Message $executionMsg
        exit
    }
}

$noMatchMsg = "No matching MAC address found in the specified network range."
Log-Message $noMatchMsg

# Calculate and log total execution time
$endTime = Get-Date
$executionTime = $endTime - $startTime
$executionMsg = "Total execution time: $executionTime"
Log-Message $executionMsg