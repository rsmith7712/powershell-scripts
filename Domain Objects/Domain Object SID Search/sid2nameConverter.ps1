﻿# LEGAL
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
.DESCRIPTION
  sid2nameConverter.ps1

.FUNCTIONALITY
  1. List of SIDs: The SIDs are stored in an array for iteration.
  2. Each SID is converted into a `SecurityIdentifier` object.
  3. The `Translate` method resolves the SID to an NT account.
  3. Error Handling: If resolution fails, "Not Found" is output for that SID.
  4. Results: A custom object is created for each SID containing SID, AccountName, and ReferencedDomainName.
  5. Formatted Table: The results are displayed in a neat table.

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
		
#>

# List of SIDs
$sids = @(
    'S-1-5-21-43593952-1852863420-8675309-1346',
    'S-1-5-21-43593952-1852863420-8675309-2231',
    'S-1-5-21-43593952-1852863420-8675309-2321',
    'S-1-5-21-43593952-1852863420-8675309-2615',
    'S-1-5-21-43593952-1852863420-8675309-2632',
    'S-1-5-21-43593952-1852863420-8675309-8067' #Known active computer SID
)

# Array to store results
$results = @()

# Loop through each SID
foreach ($sid in $sids) {
    try {
        # Create a SecurityIdentifier object
        $sidObject = New-Object System.Security.Principal.SecurityIdentifier($sid)

        # Translate SID to NT Account
        $account = $sidObject.Translate([System.Security.Principal.NTAccount])

        # Split into domain and account name
        $parts = $account.ToString().Split("\")
        $domain = $parts[0]
        $accountName = $parts[1]

        # Store result
        $results += [PSCustomObject]@{
            SID       = $sid
            Account   = $accountName
            Domain    = $domain
        }
    } catch {
        # Handle unresolved SIDs
        $results += [PSCustomObject]@{
            SID       = $sid
            Account   = "Not Found"
            Domain    = "Not Found"
        }
    }
}

# Output results in a formatted table
$results | Format-Table -AutoSize
