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
    See HISTORY section at bottom of script for development updates.
#>

# Define core paths
$ScriptName = "MonitorFileCopy.ps1"
$TargetFolder = "C:\Scripts"
$LogFolder = "C:\Scripts\Logs"
$ScriptFullPath = "$TargetFolder\$ScriptName"

# Initialize logging buffer and settings
$LogBuffer = @()
$LogFlushInterval = 10  # Flush logs every 10 seconds

# -------------------------------
# Function: Write Log
# -------------------------------
function Write-Log {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp - $Message"
    $LogBuffer += $LogEntry

    # Flush buffer periodically to reduce I/O overhead
    if ($LogBuffer.Count -ge 10) {
        Flush-Log
    }
}

function Flush-Log {
    $LogFile = "$LogFolder\Activity-MonitorFileCopy-$(Get-Date -Format "yyyy-MM-dd").log"
    if (-not (Test-Path $LogFolder)) {
        New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
    }
    $LogBuffer | Out-File -FilePath $LogFile -Append -Encoding UTF8
    $LogBuffer = @()  # Clear buffer
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
# Step 2: File Paths and Monitoring Setup
# -------------------------------
$SourceFolder = "C:\Planning Report Data Sources"
$DestinationFolder = "E:\Planning Report Data Sources"

Write-Log "Script execution started. Monitoring folder: $SourceFolder"

# -------------------------------
# Step 3: Initial Synchronization
# -------------------------------
Write-Log "Starting optimized initial synchronization of files..."

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

Write-Log "Optimized initial synchronization complete."

# -------------------------------
# Step 4: File Monitoring Setup
# -------------------------------
# Initialize a single FileSystemWatcher for all CSV files in the folder
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $SourceFolder
$watcher.Filter = "*.csv"  # Monitor all .csv files
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
# Step 5: Continuous Execution
# -------------------------------
Write-Host "Monitoring folder for changes: $SourceFolder"
Write-Host "Logs will be stored in: $LogFolder"
Write-Log "File monitoring initialized."

while ($true) {
    Start-Sleep -Seconds $LogFlushInterval
    Flush-Log
}

# FUNCTIONALITY: STEP 1: PREPARE THE SCRIPT
<# STAGE 1
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
# FUNCTIONALITY: FINAL THOUGHTS
<# FINAL
    Script updates now ensures the following:
        - Automatic relocation to C:\Scripts.
        - Administrator relaunch for proper execution.
        - Detailed logging with timestamps.
        - Survivability after a system reboot using Task Scheduler.
    The updated approach ensures robustness, clear logging, and
    self-healing for long-term automated monitoring.
#>

# HISTORY: 2024-12-17 UPDATE 6
<# U6
SUMMARY:
    Script now includes a pre-check during the initial
    script launch to compare the Date Modified timestamps of the source
    and destination files. If the destination files are older (or
    missing), the script will initiate a copy of the source files to
    update the destination files.
KEY UPDATES:
    - Initial Synchronization:
        > The script compares the LastWriteTime (Date Modified) of
        each file in the source and destination.
        > If the destination file is older or missing, it copies the
        source file to the destination.
        > Logs the action taken for transparency.
    - File Comparison:
        > Uses (Get-Item $SourceFile).LastWriteTime to fetch the
        file's Date Modified timestamp.
    - Preserved File Monitoring:
        > After the initial comparison, the script initializes
        FileSystemWatcher objects to monitor file changes.
    - Logs:
        > Detailed log entries are created for:
            *Outdated or missing files that are copied.
            *Files that are already up-to-date.
            *Errors encountered during the initial synchronization.
EXECUTION FLOW:
    - When the script starts:
        > It checks each file defined in $FilesToMonitor to ensure
        the destination files are up-to-date.
        > Any outdated or missing file is immediately copied.
    - After synchronization:
        > The script continues monitoring file changes in real-time
        using FileSystemWatcher.
    - Logs:
        > All operations (initial synchronization and file changes)
        are recorded in daily log files.
#>
# HISTORY: 2024-12-17 UPDATE 5
<# U5
TROUBLESHOOTING:
    - Observed behavior indicates two key problems:
        > File Replication Issue: 
            *The log shows report2.csv being copied, even when the
            trigger was a change to report1.csv. This is due to how
            the Register-ObjectEvent dynamically handles file names
            during the action execution.
        > Robocopy Issue:
            *Despite being reported as copied, the files' "Date
            Modified" timestamps and content are not updated. This
            strongly suggests that Robocopy is unsuitable for
            overwriting small files in scenarios where the source is
            continuously changing or that Robocopy caching/skip logic
            is interfering.
SOLUTION:
    - Instead of relying on Robocopy, we will switch to PowerShell's
    built-in Copy-Item cmdlet, which:
        > Provides simpler and more predictable behavior.
        > Allows you to force overwrites without file size/timestamp
        checks.
CODE UPDATES:
    - Accurate File Triggering: 
        > Ensures the correct file is processed on a change.
    - Reliable Copying:
        > Uses Copy-Item -Force to overwrite files explicitly.
KEY UPDATES:
    - Accurate File Handling:
        > $Event.SourceEventArgs.FullPath dynamically captures the
        full path of the file that triggered the event.
        > Prevents unrelated files (e.g., report2.csv) from being
        incorrectly processed.
    - Switch to Copy-Item:
        > Copy-Item with the -Force flag reliably overwrites files
        in the destination folder.
        > Avoids Robocopy's skipping logic based on timestamps or
        file sizes.
    - Detailed Logging:
        > Each operation logs the specific file being copied and
        any errors encountered.
BENEFITS OF USING COPY-ITEM OVER ROBOCOPY:
    - Simpler and more predictable behavior.
    - No reliance on external tools like Robocopy.
    - Reliable file overwriting with the -Force parameter.
FINAL NOTES:
    - This approach resolves the file replication issue and
    ensures reliable copying.
    - Copy-Item provides simplicity and avoids the complexities
    of Robocopy in this scenario.
    - Logs clearly document the file changes, making
    troubleshooting easier.
#>
# HISTORY: 2024-12-17 UPDATE 4
<# U4
The updated script dynamically monitors multiple files using a loop.
    - It ensures:
        > Efficient file monitoring for multiple files.
        > Robust logging for each change and copy operation.
        > File overwrites using Robocopy with the /IS and /IT flags.
    By deploying this script and configuring a Scheduled Task, you can
    ensure automated file monitoring and copying for multiple files
    across reboots.
KEY UPDATES:
    - $FilesToMonitor Array:
        > Define the list of files to monitor using this array:
        $FilesToMonitor = @("report.xlsx", "report2.xlsx")
    - Dynamic FileSystemWatcher Creation:
        > A foreach loop initializes a FileSystemWatcher for each file
        in the array.
        > Each watcher monitors the file's LastWrite changes and
        triggers the robocopy action.
    - File Change Action:
        > The script dynamically identifies the file that changed and
        logs the details.
        > Robocopy explicitly copies the changed file to the
        destination folder using:
        robocopy $SourceFolder $DestinationFolder $file "/Z /R:3 /W:5 /IS /IT"
    - Detailed Logging:
        > Each detected file change is logged with the file name,
        date, and time.
#>
# HISTORY: 2024-12-17 UPDATE 3
<# U3
TROUBLESHOOTING: 
    - The script detects file changes, launches, reports in log file
    that it copies file from source location to destination location,
    but in the destination location, the file's Date Modified value
    does not change, nor are the updates from the source file appearing
    in the destination. The source file will be overwriting an existing
    file in the destination folder with the same name.
CAUSE:
    - [Summary] The issue occurs because Robocopy skips overwriting files
    with the same timestamp and size. By adding the /IS and /IT flags, we
    explicitly instruct Robocopy to overwrite the file every time a
    change is detected, ensuring the updated file is always copied to
    the destination.
    - [Adt'l Info] Robocopy is skipping the file because:
        > The source file's Date Modified timestamp and size are
        identical to the destination file.
        > Even though the file contents may have changed, the timestamp
        may not be updated immediately or correctly due to certain
        systems/applications caching file metadata.
SOLUTION:
    - Address the issue by explicitly forcing Robocopy to overwrite
    files regardless of timestamps or sizes.
CODE UPDATES:
    - Replace the current Robocopy line:
    [Current] robocopy (Split-Path $SourceFile) $DestinationFolder (Split-Path $SourceFile -Leaf) "/Z /R:3 /W:5" | Out-Null
    [Updated] robocopy (Split-Path $SourceFile) $DestinationFolder (Split-Path $SourceFile -Leaf) "/Z /R:3 /W:5 /IS /IT" | Out-Null
EXPLANATION OF UPDATED ROBOCOPY FLAGS:
    - /IS: Copies files even if they are the same size (ignores size
    comparison).
    - /IT: Copies files even if they have the same timestamp (ignores
    timestamp comparison).
    - /Z: Copies files in restartable mode (resumable on failure).
    - /R:3: Retries the copy operation 3 times if it fails.
    - /W:5: Waits 5 seconds between retries.
    These flags ensure that the destination file is always overwritten,
    even if the Date Modified timestamp and file size appear unchanged.
#>
# HISTORY: 2024-12-17 UPDATE 2
<# U2
Updated detailed steps for implementation
#>
# HISTORY: 2024-12-17 UPDATE 1
<# U1
Below are the updated features added:
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
#>
# HISTORY: 2024-12-16 UPDATE
<# U
    Rewrite to leverage FileSystemWatcher instead of Robocopy.
    FSW is a .NET object available in PowerShell, and allows the
    script to react immediately to changes, rather than polling
    as it is event-driven, only triggers when the file changes,
    and reacts instantly to LastWrite updates.
#>
# HISTORY: 2024-12-16 CREATED
<# C
    Issue triggering script creation:
        - Create a PowerShell script leveraging Robocopy to monitor a specific
        file name and when it's Date Modified changes the script is triggered
        to copy the file from "C:\Planning Report Data Sources" to
        "E:\Planning Report Data Sources".
#>