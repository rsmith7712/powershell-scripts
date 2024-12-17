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
    STEP 1: PREPARE THE SCRIPT
    **************************
        Save the Script:
            - Save the script to any location, e.g., C:\Temp\MonitorFileCopy.ps1.
        Run the Script:
            -Run script manually in PowerShell:
            powershell.exe -ExecutionPolicy Bypass -File "C:\Temp\MonitorFileCopy.ps1"
        Automatic Relocation:
            - If the script is not in C:\Scripts, it:
                > Creates C:\Scripts if it doesn’t exist.
                > Copies itself to C:\Scripts\MonitorFileCopy.ps1.
                > Relaunches the script as an Administrator.
                > Logs the activity in C:\Scripts\Logs.
        Log Folder Creation:
            - Validates and creates C:\Scripts\Logs automatically.
        Daily Log Management:
            - Logs are stored in the format:
            C:\Scripts\Logs\Activity-MonitorFileCopy-YYYY-MM-DD.log
            - Each log entry includes:
                > Date and time in yyyy-MM-dd HH:mm:ss format.
                > Execution details, file changes, errors, and updates.
        File Monitoring:
            - Monitors C:\Planning Report Data Sources\report.xlsx.
            - On a change, it uses Robocopy to copy the file to
            E:\Planning Report Data Sources.
            - Logs success or error messages.
    
    STEP 2: SCHEDULE THE SCRIPT WITH TASK SCHEDULER
    ***********************************************
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

    
    STEP 3: VERIFY SCHEDULED TASK BEHAVIOR
    **************************************
        Reboot the System:
            - Restart the computer to ensure the task runs on startup.
            - Check Task Scheduler:
                > Open Task Scheduler and check the History tab for the task to
                confirm it started successfully.
                > Check C:\Scripts\Logs for activity.
            - Test File Monitoring:
                > Modify the monitored file to trigger the FileSystemWatcher.
                > Verify:
                    *The fileis copied to the destination folder.
                    *A log entry is created in C:\Scripts\Logs.
                > Restart the system to confirm the Scheduled Task runs
                automatically and logs its startup.

    STEP 4: ENSURE SURVIVABILITY
    ****************************
        Permissions:
            - Ensure the account running the script has:
                > Read access to the source file.
                > Write access to the destination folder.
            - Use an account with administrative privileges for the Scheduled
            Task.
        Execution Policy:
            - The -ExecutionPolicy Bypass argument ensures the script runs
            regardless of system restrictions.
        

    FINAL THOUGHTS
    **************
        Script updates now ensures the following:
            - Automatic relocation to C:\Scripts.
            - Administrator relaunch for proper execution.
            - Detailed logging with timestamps.
            - Survivability after a system reboot using Task Scheduler.
        The updated approach ensures robustness, clear logging, and
        self-healing for long-term automated monitoring.

.NOTES
2024-12-17:[UPDATES]
    (1) Below are the updated features added:
        Script Location Validation:
            - Ensures the script is executed from C:\Scripts.
        Automatic Relocation:
            - If not in C:\Scripts, copies itself and restarts with
            administrative privileges.
        Log Management:
            - Creates detailed logs stored in C:\Scripts\Logs with daily
            activity recording.
        Logging Format:
            - Logs entries with date (yyyy-MM-dd) and time
            (HH:mm:ss) in a structured format.
    (2) Updated detailed steps for implementation

2024-12-16:[UPDATES]
    Rewrite to leverage FileSystemWatcher instead of Robocopy.
    FSW is a .NET object available in PowerShell, and allows the
    script to react immediately to changes, rather than polling
    as it is event-driven, only triggers when the file changes,
    and reacts instantly to LastWrite updates.

2024-12-16:[CREATED]
    Issue triggering script creation:
        - Create a PowerShell script leveraging Robocopy to monitor a specific
        file name and when it's Date Modified changes the script is triggered
        to copy the file from "C:\Planning Report Data Sources" to
        "E:\Planning Report Data Sources".
#>

# Define core paths
$ScriptName = "MonitorFileCopy.ps1"
$TargetFolder = "C:\Scripts"
$LogFolder = "C:\Scripts\Logs"
$ScriptFullPath = "$TargetFolder\$ScriptName"

# -------------------------------
# Function: Write Log
# -------------------------------
function Write-Log {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogFile = "$LogFolder\Activity-MonitorFileCopy-$(Get-Date -Format "yyyy-MM-dd").log"

    # Create log folder if it doesn't exist
    if (-not (Test-Path -Path $LogFolder)) {
        New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
    }

    # Write to log file
    Add-Content -Path $LogFile -Value "$Timestamp - $Message"
}

# -------------------------------
# Step 1: Validate Script Location
# -------------------------------
if ($PSScriptRoot -ne $TargetFolder) {
    Write-Host "Script is not running from $TargetFolder. Moving script..."
    Write-Log "Script not in $TargetFolder. Moving script."

    # Create target folder if it doesn't exist
    if (-not (Test-Path -Path $TargetFolder)) {
        New-Item -Path $TargetFolder -ItemType Directory -Force | Out-Null
        Write-Log "Created folder: $TargetFolder"
    }

    # Copy script to target folder
    Copy-Item -Path $MyInvocation.MyCommand.Definition -Destination $ScriptFullPath -Force
    Write-Log "Copied script to $TargetFolder"

    # Relaunch script in administrator mode
    Write-Host "Restarting script in administrative mode..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File $ScriptFullPath" -Verb RunAs
    Write-Log "Relaunched script as Administrator."

    # Exit old session
    exit
}

# -------------------------------
# Step 2: File Monitoring Setup
# -------------------------------
# Define file paths for monitoring and copying
$SourceFile = "C:\Planning Report Data Sources\report.xlsx"
$DestinationFolder = "E:\Planning Report Data Sources"

Write-Log "Script execution started. Monitoring file: $SourceFile"

# Initialize FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = (Split-Path $SourceFile)
$watcher.Filter = (Split-Path $SourceFile -Leaf)
$watcher.NotifyFilter = [System.IO.NotifyFilters]'LastWrite'

# Action on file change
$action = {
    Write-Log "Change detected in $SourceFile. Copying to $DestinationFolder."
    try {
        # Execute Robocopy
        robocopy (Split-Path $SourceFile) $DestinationFolder (Split-Path $SourceFile -Leaf) "/Z /R:3 /W:5" | Out-Null
        Write-Log "File copied successfully to $DestinationFolder"
    }
    catch {
        Write-Log "Error during file copy: $_"
    }
}

# Register FileSystemWatcher Event
Register-ObjectEvent $watcher "Changed" -Action $action

# -------------------------------
# Step 3: Continuous Execution
# -------------------------------
Write-Host "Monitoring file changes for: $SourceFile"
Write-Host "Logs will be stored in: $LogFolder"
Write-Log "File monitoring initialized."

# Keep script alive
while ($true) {
    Start-Sleep -Seconds 1
}