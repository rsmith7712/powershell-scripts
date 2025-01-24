# LEGAL
<# LICENSE
    MIT License, Copyright 2024 Richard Smith

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
    AD-DomainComputersListValidationAgainstAD-DNS-PING.ps1
.ps1

.SYNOPSIS
  Import list of computer names from a text file and verify if instances are
  found in Active Directory, DNS, Responds to PING.

.FUNCTIONALITY
  -Import ActiveDirectory module: This is needed to interact with Active Directory.
  -Read computer names: The script reads computer names from a text file.
  -Iterate through computer names: The script loops through each computer name.
  -Check in AD: The Get-ADComputer cmdlet is used to check if the computer exists in AD.
  -Check in DNS: The Resolve-DnsName cmdlet is used to check if the computer name has a DNS record.
  -Check PING: If computer is found in Active Directory, script checks if it responds to ping using the Test-Connection cmdlet.
  -Create result object: A custom object is created to store the results for each computer.
  -Output and Export: The results are displayed in a table format and can optionally be exported to a CSV file.

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts - AD-Domain Computers List Validation Against AD-DNS-PING
#>

# Import the ActiveDirectory module if not already loaded
Import-Module ActiveDirectory -ErrorAction SilentlyContinue 

# Read computer names from a text file
$computerNames = Get-Content -Path "C:\temp\Source\computernames.txt"

# Create an output array to store results
$results = @()

# Loop through each computer name
foreach ($computerName in $computerNames) {
    # Check in Active Directory
    $adComputer = Get-ADComputer -Filter "Name -like '$computerName'" -ErrorAction SilentlyContinue

    # Check in DNS 
    $dnsResult = Resolve-DnsName -Name $computerName -ErrorAction SilentlyContinue

    # Check if computer responds to PING
    $pingResult = Test-Connection -ComputerName $computerName -Count 1 -Quiet

    # Create a custom object for the results
    $result = [PSCustomObject]@{
        ComputerName = $computerName
        ExistsInAD = [bool]$adComputer
        ExistsInDNS = [bool]$dnsResult
        PINGABLE = [bool]$pingResult
    }
    $results += $result
}
# Output the results
$results | Format-Table -AutoSize

# Optionally, export the results to a CSV file
$results | Export-Csv -Path "C:\temp\results.csv" -NoTypeInformation