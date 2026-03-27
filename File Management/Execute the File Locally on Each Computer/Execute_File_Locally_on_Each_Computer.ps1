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
    Execute_File_Locally_on_Each_Computer.ps1

.DESCRIPTION
    Execute a file locally on each computer in a list

.FUNCTIONALITY
    This script is designed to execute a file locally on each computer in a list.  The
    script will read a list of computer names from a text file, check if each computer is
    reachable, and then execute the specified file on each reachable computer while saving
    the results to a specified location.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# Prompt for Domain Admin credentials at the start of the script
$domainAdminCred = Get-Credential -Message "Please enter Domain Admin credentials"

$computers = Get-Content -Path "C:\temp\computers.txt"
$resultsFolder = "C:\temp\Win11Results"

foreach ($computer in $computers) {
    if (Test-Connection -ComputerName $computer -Quiet) {
        $resultsFile = "\\$computer\C$\temp\Win11_Results_$computer.csv"

        # Define the script block and pass the $resultsFile variable explicitly
        $scriptBlock = {
            param($resultsFile)

            # Ensure the directory exists
            $resultsFolder = "C:\temp"
            if (-not (Test-Path $resultsFolder)) {
                New-Item -Path $resultsFolder -ItemType Directory
            }

            # Run the executable and output to the results file
            & "C:\temp\WhyNotWin11.exe" | Out-File $resultsFile
        }

        try {
            # Invoke the command with Domain Admin credentials, passing $resultsFile as a parameter
            Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock -ArgumentList $resultsFile -Credential $domainAdminCred
            Write-Host "Executed on $computer and saved results to $resultsFile"
        } catch {
            # Capture the exception message and output it correctly
            $errorMessage = $_.Exception.Message
            Write-Warning "Failed to execute file on ${computer}: $errorMessage"
        }
    } else {
        Write-Warning "$computer is not reachable, skipping..."
        continue  # Skip to the next computer if unreachable
    }
}