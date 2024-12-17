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

.NAME
    MonitorFileCopy-v0.ps1

.SYNOPSIS


.FUNCTIONALITY
    Monitors the File:
        - The script checks the LastWriteTime property of the
            target file every 5 seconds.
    Trigger Condition:
        - If the "Date Modified" changes, it triggers a
            Robocopy operation.
    Robocopy Execution:
        - Copies the updated file from C:\Planning Report Data
            Sources to E:\Planning Report Data Sources.
        - Ensures the operation is resumable and retries in case
            of temporary failure.
    Output:
        - Logs actions to the terminal, showing when a file
            change is detected and when the copy operation
            completes.

.NOTES

2024-12-16:[CREATED]
    Let the troubleshooting and fun begin.

#>

# Define source and destination paths
$SourceFile = "C:\Planning Report Data Sources\report.xlsx"  # Replace with your file name
$DestinationFolder = "E:\Planning Report Data Sources"

# Robocopy options
$RobocopyOptions = "/Z /R:3 /W:5"  # Retry 3 times, wait 5 seconds between retries, resume on failure

# Initial file state
$LastModified = (Get-Item $SourceFile).LastWriteTime

Write-Host "Monitoring file changes for: $SourceFile"
Write-Host "Press Ctrl+C to stop the script."

# Continuous monitoring loop
while ($true) {
    try {
        # Check if the file still exists
        if (Test-Path $SourceFile) {
            $CurrentModified = (Get-Item $SourceFile).LastWriteTime

            # Trigger action if the file's Last Modified timestamp changes
            if ($CurrentModified -ne $LastModified) {
                Write-Host "Change detected. Copying file to destination..."

                # Execute Robocopy
                robocopy (Split-Path $SourceFile) $DestinationFolder (Split-Path $SourceFile -Leaf) $RobocopyOptions

                # Update the last modified timestamp
                $LastModified = $CurrentModified

                Write-Host "File successfully copied at $(Get-Date)"
            }
        } else {
            Write-Host "Error: File does not exist at $SourceFile"
        }
    } catch {
        Write-Host "Error: $_"
    }

    Start-Sleep -Seconds 5  # Check every 5 seconds
}