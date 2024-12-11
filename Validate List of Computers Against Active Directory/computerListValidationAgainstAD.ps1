<#
.LICENSE
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

.DESCRIPTION
  Import list of computer names from a text file and verify if instances are
  found in Active Directory, DNS, Responds to PING, and LastLogon details.

.FUNCTIONALITY
  -Import ActiveDirectory module
  -Read computer names from a text file
  -Script loops through each computer name
  -Check AD: Get-ADComputer used to check if exists in AD
  -Check DNS: Resolve-DnsName used to check if DNS record exists
  -Check PING: Test-Connection used if CN found in AD, check if responds to
    ping
  -Create result object: A custom object is created to store the results for
    each computer. [PSCustomObject]
  -Output and Export: The results are displayed in a table format and can
    optionally be exported to a CSV file.

.NOTES
  -LastLogonDate vs LastLogonTimeStamp: The LastLogonDate attribute in Active
  Directory is not always accurate, as it is not replicated across all domain
  controllers. The LastLogonTimeStamp attribute is more reliable, but it
  requires conversion from file time to a readable date and time.

  -Last Activity: Script does not retrieve the last activity time, as it
  is not directly available in Active Directory. You may need to use other
  methods, such as event log analysis, to determine the last activity time
  for a computer.

#>

# Import the Active Directory module if not already loaded
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

# Read computer names from a text file
$computerNames = Get-Content -Path "C:\temp\Source\computernamesFullList.txt"

# Create an output array to store results
$results = @()

# Loop through each computer name
foreach ($computerName in $computerNames) {
    try {
        # Get computer object from Active Directory
        $adComputer = Get-ADComputer -Filter "Name -eq '$computerName'" -Properties LastLogonTimeStamp -ErrorAction SilentlyContinue

        # Check if computer exists in DNS
        $dnsResult = Resolve-DnsName -Name $computerName -ErrorAction SilentlyContinue

        # Check if the computer responds to PING
        $pingResult = Test-Connection -ComputerName $computerName -Count 1 -Quiet

        # Process results
        $lastLogon = if ($adComputer) {
            if ($adComputer.LastLogonTimeStamp) {
                ([DateTime]::FromFileTime($adComputer.LastLogonTimeStamp)).ToString("yyyy-MM-dd HH:mm")
            } else {
                "Never Logged On"
            }
        } else {
            "Not Found in AD"
        }

        # Add the computer information to the results
        $results += [PSCustomObject]@{
            ComputerName = $computerName
            ExistsInAD   = [bool]$adComputer
            ExistsInDNS  = ($dnsResult -ne $null)
            PINGABLE     = $pingResult
            LastLogon    = $lastLogon
        }
    }
    catch {
        # Handle errors and add to results
        $results += [PSCustomObject]@{
            ComputerName = $computerName
            ExistsInAD   = $false
            ExistsInDNS  = $false
            PINGABLE     = $false
            LastLogon    = "Error: $_"
        }
    }
}

# Output the results
$results | Format-Table -AutoSize

# Optionally, export the results to a CSV file
$results | Export-Csv -Path "C:\temp\Results\results-cn-validation.csv" -NoTypeInformation -Force