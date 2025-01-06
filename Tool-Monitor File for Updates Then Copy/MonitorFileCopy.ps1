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
    MonitorFileCopy.ps1

.SYNOPSIS
    Monitors the File:
        - The script checks the LastWriteTime property of the
            target file.
    Trigger Condition:
        - If the "Date Modified" changes, it triggers a
            FileSystemWatcher operation.
    Robocopy Execution:
        - Copies the updated file from C:\Planning Report Data
            Sources to E:\Planning Report Data Sources.
        - Ensures the operation is resumable and retries in case
            of temporary failure.
    Output:
        - Logs actions to the terminal, showing when a file
            change is detected and when the copy operation
            completes.

.FUNCTIONALITY
    See FUNCTIONALITY section at bottom of script for detailed instructions
    on setting up this script, and the associated Scheduled Task.

.NOTES
    To view history and change notes, reference:
    https://github.com/rsmith7712 
    PowerShell-Scripts - Tool-Monitor File for Updates Then Copy
#>

# Define core paths
$ScriptName = "MonitorFileCopy.ps1"
$LogBaseFolder = "C:\Temp\Logs\MonitorFileCopy"
$LogFlushInterval = 10  # Flush logs every 10 seconds
$StartTime = Get-Date  # Record script start time
$LogBuffer = @()

# -------------------------------
# Function: Write Log
# -------------------------------
function Write-Log {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp - $Message"
    $LogBuffer += $LogEntry

    # Flush log periodically
    if ($LogBuffer.Count -ge 10) {
        Flush-Log
    }
}

function Flush-Log {
    # Generate new log file name daily
    $LogFile = "$LogBaseFolder\log-MonitorFileCopy-$(Get-Date -Format "yyyy-MM-dd-HH-mm").txt"

    # Create log folder if it doesn't exist
    if (-not (Test-Path -Path $LogBaseFolder)) {
        New-Item -Path $LogBaseFolder -ItemType Directory -Force | Out-Null
    }

    # Write log buffer to log file
    $LogBuffer | Out-File -FilePath $LogFile -Append -Encoding UTF8
    $LogBuffer = @()  # Clear buffer
}

# -------------------------------
# Function: Log Script Completion
# -------------------------------
function Log-ScriptCompletion {
    $EndTime = Get-Date
    $ExecutionTime = $EndTime - $StartTime
    Write-Log "Script completed at: $($EndTime -Format "yyyy-MM-dd HH:mm:ss"). Total execution time: $($ExecutionTime.TotalMinutes) minutes, $($ExecutionTime.TotalSeconds) seconds."
    Flush-Log
}

# -------------------------------
# Step 1: File Paths and Monitoring Setup
# -------------------------------
$SourceFolder = "C:\Planning Report Data Sources"
$DestinationFolder = "E:\Planning Report Data Sources"

Write-Log "Script execution started at: $($StartTime -Format "yyyy-MM-dd HH:mm:ss"). Monitoring folder: $SourceFolder"

# -------------------------------
# Step 2: Initial Synchronization
# -------------------------------
Write-Log "Starting initial synchronization of files..."

$SourceFiles = Get-ChildItem -Path $SourceFolder -Filter "*.csv"

foreach ($SourceFile in $SourceFiles) {
    $DestinationFile = Join-Path -Path $DestinationFolder -ChildPath $SourceFile.Name

    if ((-not (Test-Path $DestinationFile)) -or ($SourceFile.LastWriteTime -gt (Get-Item $DestinationFile).LastWriteTime)) {
        try {
            Write-Log "Destination file '$($SourceFile.Name)' is outdated or missing. Copying to destination..."
            Copy-Item -Path $SourceFile.FullName -Destination $DestinationFile -Force
            Write-Log "File '$($SourceFile.Name)' successfully copied to destination."
        }
        catch {
            Write-Log "Error copying file '$($SourceFile.Name)': $_"
        }
    }
    else {
        Write-Log "Destination file '$($SourceFile.Name)' is up-to-date. No action taken."
    }
}

Write-Log "Initial synchronization complete."

# -------------------------------
# Step 3: File Monitoring Setup
# -------------------------------
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $SourceFolder
$watcher.Filter = "*.csv"
$watcher.IncludeSubdirectories = $false
$watcher.NotifyFilter = [System.IO.NotifyFilters]'LastWrite'

# Action on file change
Register-ObjectEvent $watcher "Changed" -Action {
    $ChangedFile = $Event.SourceEventArgs.FullPath
    $FileName = (Split-Path $ChangedFile -Leaf)
    $DestinationFile = Join-Path -Path $DestinationFolder -ChildPath $FileName

    Write-Log "Change detected in $ChangedFile. Queuing file for copy..."

    # Asynchronous file copy
    Start-Job -ScriptBlock {
        param($Source, $Destination, $LogFunction)
        try {
            Copy-Item -Path $Source -Destination $Destination -Force
            &$LogFunction "File '$(Split-Path $Source -Leaf)' copied successfully to $Destination."
        }
        catch {
            &$LogFunction "Error copying file '$(Split-Path $Source -Leaf)': $_"
        }
    } -ArgumentList $ChangedFile, $DestinationFile, ${function:Write-Log}
}

# -------------------------------
# Step 4: Continuous Execution
# -------------------------------
Write-Host "Monitoring folder for changes: $SourceFolder"
Write-Host "Logs will be stored in: $LogBaseFolder"
Write-Log "File monitoring initialized. Script is running."

# Main loop for periodic log flushing
try {
    while ($true) {
        Start-Sleep -Seconds $LogFlushInterval
        Flush-Log
    }
}
finally {
    Log-ScriptCompletion
}

# FUNCTIONALITY: STEP 1: Deployment Instructions
<# STAGE 1
    Save the Script:
        - Save the script to any location, e.g., C:\Temp\MonitorFileCopy.ps1.
    Run the Script:
        -Run script manually in PowerShell:
        powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\MonitorFileCopy.ps1"
    Automatic Relocation:
        - If the script is not in C:\Scripts, it:
            > Creates C:\Scripts if it doesn’t exist.
            > Copies itself to C:\Scripts\MonitorFileCopy.ps1.
            > Relaunches the script as an Administrator.
            > Logs the activity in C:\temp\Logs\MonitorFileCopy.
    Log Folder Creation:
        - Validates and creates C:\temp\Logs\MonitorFileCopy automatically.
    Daily Log Management:
        - Logs are stored in the format:
        C:\temp\Logs\MonitorFileCopy\log-MonitorFileCopy-YYYY-MM-DD-HH-mm.txt
        - Each log entry includes:
            > Date and time in yyyy-MM-dd HH:mm:ss format.
            > Execution details, file changes, errors, and updates.
    File Monitoring:
        - Monitors C:\Planning Report Data Sources\report.xlsx.
        - On a change, it uses Robocopy to copy the file to
        E:\Planning Report Data Sources.
        - Logs success or error messages.
#>
# FUNCTIONALITY: STEP 2: SCHEDULE THE SCRIPT WITH TASK SCHEDULER
<# STAGE 2
    To ensure the script runs automatically at startup after a reboot, 
    configure a Scheduled Task in Windows Task Scheduler.
    Open Task Scheduler:
        - Press Win + R, type taskschd.msc, and press Enter.
    Create a New Task:
        - Click Create Task on the right-hand side.
    General Tab:
        - Name: MonitorFileCopy
        - Description: "Monitors file changes and copies them automatically."
        - Security options:
            > Select Run whether user is logged on or not.
            > Check Run with highest privileges (ensures it runs
            with admin permissions).
    Triggers Tab:
        - Click New... to create a trigger.
        - Configure as follows:
            > Begin the task: At startup
            > Check Enabled.
        - Click OK.
    Actions Tab:
        - Click New... to add an action.
        - Configure as follows:
            > Action: Start a program
        >EITHER<
            # PowerShell 5x
            > Program/script: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
        >OR<
            #PowerShell 7x    
            > Program/script: C:\Program Files\PowerShell\7\pwsh.exe
            > Add arguments: -ExecutionPolicy Bypass -File "C:\Scripts\MonitorFileCopy.ps1"
        - Click OK.
    Conditions Tab:
        - Uncheck "Start the task only if the computer is on AC power" 
        to ensure it runs if on laptops running on battery.
    Settings Tab:
        - Check:
            > Allow task to be run on demand
            > Run task as soon as possible after a scheduled start is missed
        - Uncheck:
            > Stop the task if it runs longer than... (the script runs
            indefinitely).
    Save and Test:
        - Click OK to save the task.
        - If prompted, provide the admin credentials.
        - Restart computer system to ensure the task runs at startup.
#>
# FUNCTIONALITY: STEP 3: VERIFY SCHEDULED TASK BEHAVIOR
<# STAGE 3
    Reboot the System:
        - Restart the computer to ensure the task runs on startup.
        - Check Task Scheduler:
            > Open Task Scheduler and check the History tab for the task to
            confirm it started successfully.
            > Check C:\Scripts\Logs for activity.
        - Test File Monitoring:
            > Modify the monitored file to trigger the FileSystemWatcher.
            > Verify:
                *Modify both monitored files (report.xlsx and report2.xlsx)
                to ensure changes trigger file copying.
                *A log entry is created in C:\Scripts\Logs.
            > Restart the system to confirm the Scheduled Task runs
            automatically and logs its startup.
#>
# FUNCTIONALITY: STEP 4: ENSURE SURVIVABILITY
<# STAGE 4
    Permissions:
        - Ensure the account running the script has:
            > Read access to the source file.
            > Write access to the destination folder.
        - Use an account with administrative privileges for the Scheduled
        Task.
    Execution Policy:
        - The -ExecutionPolicy Bypass argument ensures the script runs
        regardless of system restrictions.
#>
# FUNCTIONALITY: STEP 5: ADDITIONAL TROUBLESHOOTING TIPS (IF NEEDED)
<# STAGE 5
    Verify File Locks:
        - Ensure no process locks the destination file, preventing
        overwrites.
        - Use tools like Handle (Sysinternals) or Resource Monitor to
        identify file locks.
    Permissions:
        - Ensure the script has proper write permissions for the
        destination folder.
        - Run the script as an Administrator.
    Testing:
        - Modify the source file and observe the log to confirm the copy
        operation.
        - Check if the destination file is updated with the new contents.
    Log Additional Details:
        - Add file metadata (e.g., timestamp, size) to the log to confirm
        what is being copied:
        $SourceInfo = Get-Item $SourceFile
        Write-Log "Source File: $SourceFile | Size: $($SourceInfo.Length) | Modified: $($SourceInfo.LastWriteTime)"
#>
# FUNCTIONALITY: STEP 6: HOW TO ADD MORE FILES TO MONITOR (IF NEEDED)
<# STAGE 6
    To monitor more files, simply add their names to the $FilesToMonitor
    array:
    $FilesToMonitor = @("report.xlsx", "report2.xlsx", "report3.xlsx", "data.csv")
#>