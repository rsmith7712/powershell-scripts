﻿<#
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

.NAME
    getRemoteComputerObjectDetails-Specific.ps1

.DESCRIPTION
    Script takes user input for a computer object name, adds
        a trailing $, queries the specified computer object,
        and retrieves details such as the current user, OS
        version, computer name, and object SID. The output
        is formatted as a table and displayed on the console.

.FUNCTIONALITY
    User Input: Prompts the user for a computer object name using Read-Host.
    Add Trailing $: Appends a $ to the input to match naming conventions for computer objects.
    Query Computer Details:
        -Win32_ComputerSystem retrieves the computer name and current logged-in user.
        -Win32_OperatingSystem retrieves the OS version.
        -Get-ADComputer retrieves the ObjectSID of the computer object from Active Directory.
    Error Handling: Catches and displays errors if the query fails.

.NOTES
2024-12-10:[ADDED]
    Script Updates:
        -Includes a check to ensure it is being run with 
        administrator privileges. If not, it will display a message and 
        exit. This ensures proper permissions for querying computer information.
        
        -Prompts the user to enter domain administrator credentials
        using Get-Credential before proceeding with execution. The provided
        credentials are used for querying the necessary computer details,
        ensuring secure and authenticated operations.

        -Added functionality to ask the user if they want to perform
        another search after displaying the results. If the user enters anything
        other than "y" or "yes," the script exits to the console prompt.

        -Saves the domain administrator credentials entered during the
        first search and reuses them for subsequent searches. This avoids
        prompting the user to re-enter credentials until they choose to exit or
        close the console window.

        -Requires domain administrator credentials to be entered before
        execution begins. The credentials are prompted at the start and reused
        for subsequent searches. Additionally, it checks for administrator
        privileges early on to ensure proper permissions.

2024-12-10:[CREATED]
    ask user to input the computer object to query, add trailing $ to user
        input, get computer object return current user, os version,
        computer name, objectSID, format table and output to console

#>

# Require domain administrator credentials before script execution
$domainCreds = Get-Credential -Message "Enter domain administrator credentials"

# Check if the script is running with administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Please run as administrator." -ForegroundColor Red
    exit
}
# Function to perform the search
function Perform-Search {
    # Prompt user for computer object name
    $computerName = Read-Host -Prompt "Enter the computer object name"

    # Add a trailing $ to the input
    $computerObject = "$computerName$"

    # Use Get-WmiObject to query the computer for details
    try {
        $computerInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computerName -Credential $domainCreds
        $osInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computerName -Credential $domainCreds
        $objectSID = (Get-ADComputer -Identity $computerName -Properties ObjectSID -Credential $domainCreds).ObjectSID

        if ($computerInfo -and $osInfo) {
            # Construct an output object
            $output = [PSCustomObject]@{
                ComputerName = $computerInfo.Name
                CurrentUser  = $computerInfo.UserName
                OSVersion    = $osInfo.Caption
                ObjectSID    = $objectSID
            }
            # Output as a formatted table
            $output | Format-Table -AutoSize
        } else {
            Write-Host "Failed to retrieve computer information." -ForegroundColor Red
        }
    } catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
}
# Loop to allow multiple searches
while ($true) {
    Perform-Search
    $continue = Read-Host -Prompt "Do you want to perform another search? (y/n)"
    if ($continue -notmatch "^y(?:es)?$") {
        Write-Host "Exiting script." -ForegroundColor Green
        break
    }
}