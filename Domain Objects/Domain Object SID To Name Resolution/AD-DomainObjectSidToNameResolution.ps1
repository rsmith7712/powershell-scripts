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
    AD-DomainObjectSidToNameResolution.ps1

.SYNOPSIS
  Import list of computer names from a text file and verify if instances are
  found in Active Directory, DNS, Responds to PING.

.FUNCTIONALITY
    1. Interactive Selection:
       - Prompts the user to select User, Computer, or Group.

    2. Object Name Input:
       - Prompts the user to enter the name of the object to search for.

    3. Automatic Formatting for Computer Names:
       - Appends $ to the object name if the selected type is Computer.

    4. Search and Export:
       - Searches Active Directory for the object.
       - Displays results in the console.
       - Exports results to a CSV file (AD_Object_SIDs.csv).

    [PROMPT]
      Select the object type you want to search for:
      1. User
      2. Computer
      3. Group
      Enter your choice (1, 2, or 3): 2
      Enter the name of the object to search for: RSMITH-LT01


    [OUTPUT TO CONSOLE]
      SID                           Account       Domain
      ----------------------------- ------------- ----------------
      S-1-5-21-1234567890-23456789  CEO-LT01      example.com

      Results exported to C:\Temp\AD_Object_SIDs.csv


    [OUTPUT TO CSV]
    SID,Account,Domain
    S-1-5-21-1234567890-2345678901-8675309012-1234,CEO-LT01,example.com


    This script is flexible and works for most AD objects.

    Run this script with sufficient permissions to resolve SIDs within your
    Active Directory environment.

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts - AD-Domain Object SID To Name Resolution
#>

# Output file path
$outputFolder = "C:\Temp"
$outputFile = "$outputFolder\AD_Object_SIDs.csv"

# Ensure the output folder exists
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
    Write-Host "Created folder: $outputFolder"
}

# Import the Active Directory module
Import-Module ActiveDirectory

# Function to perform a search
function Perform-Search {
    # Prompt user to select the object type
    Write-Host "Select the object type you want to search for:"
    Write-Host "1. User"
    Write-Host "2. Computer"
    Write-Host "3. Group"
    $objectTypeChoice = Read-Host "Enter your choice (1, 2, or 3)"

    # Map user input to object type
    switch ($objectTypeChoice) {
        "1" { $objectType = "User" }
        "2" { $objectType = "Computer" }
        "3" { $objectType = "Group" }
        default { 
            Write-Host "Invalid choice. Returning to menu."
            return
        }
    }

    # Prompt for object name
    $objectName = Read-Host "Enter the name of the object to search for: "

    # Append trailing $ if searching for a Computer account
    if ($objectType -eq "Computer" -and -not $objectName.EndsWith('$')) {
        $objectName += "$"
    }

    # Array to store results
    $results = @()

    # Query Active Directory
    try {
        switch ($objectType) {
            "User" {
                $adObject = Get-ADUser -Filter { SamAccountName -eq $objectName } -Properties SID
            }
            "Computer" {
                $adObject = Get-ADComputer -Filter { SamAccountName -eq $objectName } -Properties SID
            }
            "Group" {
                $adObject = Get-ADGroup -Filter { SamAccountName -eq $objectName } -Properties SID
            }
            default {
                throw "Unsupported object type: $objectType"
            }
        }

        # Check if an object was found
        if ($adObject) {
            $results += [PSCustomObject]@{
                SID     = $adObject.SID.Value
                Account = $adObject.Name
                Domain  = $adObject.DistinguishedName -split ',' | Where-Object { $_ -match '^DC=' } -join '.'
            }

            Write-Host "Object found:"
            $results | Format-Table -AutoSize
        } else {
            Write-Host "No object found with the name '$objectName' in Active Directory."
        }
    } catch {
        Write-Host "An error occurred: $_"
    }

    # Export results to CSV if any results were found
    if ($results.Count -gt 0) {
        $results | Export-Csv -Path $outputFile -NoTypeInformation
        Write-Host "Results exported to $outputFile"
    } else {
        Write-Host "No results to export."
    }
}

# Main loop
do {
    Perform-Search
    $continueSearch = Read-Host "Would you like to perform another search? (y/n)"
} while ($continueSearch -eq "y")

Write-Host "Exiting script. Goodbye!"