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
    aFileSystemWatcher.ps1

.SYNOPSIS


.FUNCTIONALITY
    Monitors the File:
        - The script checks the LastWriteTime property of the target file
            every 5 seconds.
    Trigger Condition:
        - If the "Date Modified" changes, it triggers a Robocopy operation.
    Robocopy Execution:
        - Copies the updated file from C:\Planning Report Data Sources to
            E:\Planning Report Data Sources.
        - Ensures the operation is resumable and retries in case of
            temporary failure.
    Output:
        - Logs actions to the terminal, showing when a file change is
            detected and when the copy operation completes.

.NOTES
2024-12-16:[UPDATES]
    (1) Improvements:
        Script works reasonably well, but a more modern and
        event-driven approach is needed. FileSystemWatcher, a
        .NET object available in PowerShell is being explored.
        This allows the script to react immediately to changes,
        rather than polling as it is event-driven, only triggers
        when the file changes, and reacts instantly to LastWrite
        updates.

2024-12-16:[CREATED]
    Let the troubleshooting and fun begin.

#>

# Define source and destination paths
$SourceFile = "C:\Planning Report Data Sources\report.xlsx"
$DestinationFolder = "E:\Planning Report Data Sources"

# Initialize FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = (Split-Path $SourceFile)
$watcher.Filter = (Split-Path $SourceFile -Leaf)
$watcher.NotifyFilter = [System.IO.NotifyFilters]'LastWrite'

Write-Host "Watching for changes to: $SourceFile"
Write-Host "Press Ctrl+C to stop the script."

# Define action on change
$action = {
    Write-Host "Change detected! Copying file..."
    robocopy (Split-Path $SourceFile) $DestinationFolder (Split-Path $SourceFile -Leaf) "/Z /R:3 /W:5"
    Write-Host "File copied successfully at $(Get-Date)"
}

# Register event
Register-ObjectEvent $watcher "Changed" -Action $action

# Keep the script alive
while ($true) { Start-Sleep -Seconds 1 }
