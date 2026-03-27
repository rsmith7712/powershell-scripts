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
    FilePusher.ps1

.DESCRIPTION
    Copy a file to multiple Windows systems

.FUNCTIONALITY
    This script is designed to copy a file to multiple Windows systems.  The
    script will query Active Directory for all Windows-based computer accounts,
    and attempt to copy a specified file to a specified folder on each system
    using PowerShell remoting.  The script will prompt for Domain Admin credentials
    to use for the remoting sessions.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# Import the Active Directory cmdlets
Import-Module ActiveDirectory -ErrorAction Stop

# Prompt for your Domain Admin credentials
$cred = Get-Credential -Message 'Enter Domain Admin credentials'

# Get all Windows–based computer names from AD
$computers = Get-ADComputer -Filter {OperatingSystem -like "*Windows*"} |
             Select-Object -ExpandProperty Name

# Local source file
$sourceFile = "C:\temp\WhyNotWin11.exe"

# Remote destination folder path
$remotePath = "C:\temp"

foreach ($computer in $computers) {
    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        try {
            # Establish a remoting session using the provided credentials
            $session = New-PSSession -ComputerName $computer -Credential $cred -ErrorAction Stop

            # Ensure the remote folder exists
            Invoke-Command -Session $session -ScriptBlock {
                param($path)
                if (-not (Test-Path $path)) {
                    New-Item -Path $path -ItemType Directory -Force | Out-Null
                }
            } -ArgumentList $remotePath

            # Copy the file into that folder over the session
            Copy-Item -Path $sourceFile `
                      -Destination $remotePath `
                      -ToSession $session `
                      -Force -ErrorAction Stop

            Write-Host "✅ File copied successfully to $computer"
        }
        catch {
            Write-Warning "❌ Failed to copy file to ${computer}: $($_.Exception.Message)"
        }
        finally {
            # Clean up the session if it was created
            if ($session) { Remove-PSSession $session }
        }
    }
    else {
        Write-Warning "⚠️  Computer $computer is not reachable"
    }
}
