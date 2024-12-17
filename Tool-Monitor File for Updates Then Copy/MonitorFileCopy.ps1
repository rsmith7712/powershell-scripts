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

.FUNCTIONALITY
    STEP 1: PREPARE THE SCRIPT
    **************************
        Save script file as: MonitorFileCopy.ps1 in a folder like:
            C:\Scripts\MonitorFileCopy.ps1
    
        **Important: Ensure the folder C:\Scripts is created and
            the script is saved with a .ps1 extension.

        Testing the script:
            -Run script manually in PowerShell:
        powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\MonitorFileCopy.ps1"

            -Make a change to the monitored file (modify contents or
            update it's timestamp).

            -Ensure file is copied successfully to the destination folder.
    
    STEP 2: CREATE A SCHEDULED TASK
    *******************************
        To ensure the script runs automatically at startup after a reboot, 
        configure a Scheduled Task in Windows Task Scheduler.

        Open Task Scheduler:
            - Press Win + R, type taskschd.msc, and press Enter.
        Create a New Task:
            - Click Create Task on the right-hand side.
        General Tab:
            - Name: MonitorFileCopy
            - Description: "Monitors file changes and copies updates to a
            destination folder."
            - Security options:
                > Select Run whether user is logged on or not.
                > Check Run with highest privileges (ensures it runs
                with admin permissions).
        Triggers Tab:
            Click New... to create a trigger.
            Configure as follows:
                > Begin the task: At startup
                >Check Enabled.
            Click OK.
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
            to ensure it runs on laptops running on battery.
        Settings Tab:
            - Check:
                > Allow task to be run on demand
                > Run task as soon as possible after a scheduled start is missed
            - Uncheck:
                > Stop the task if it runs longer than... (the script runs indefinitely).
            - Save and Test:
                > Click OK to save the task.
                > If prompted, provide the admin credentials.
    
    STEP 3: VERIFY SCHEDULED TASK BEHAVIOR
    **************************************
        Reboot the System:
            - Restart the computer to ensure the task runs on startup.
            - Check Task Scheduler:
                > Open Task Scheduler and check the History tab for the
                task to confirm it started successfully.
            - Test File Monitoring:
                > Modify the monitored file (e.g., edit or save it to
                trigger a "LastWrite" update).
                > Verify that the file is copied to the destination folder.

    STEP 4: ENSURE SURVIVABILITY AND TROUBLESHOOTING
    ************************************************
        Permissions:
            - Ensure the account running the script has:
                > Read access to the source file.
                > Write access to the destination folder.
            - Use an account with administrative privileges for the Scheduled Task.
        Execution Policy:
            - The -ExecutionPolicy Bypass argument ensures the script
            runs regardless of system restrictions.
        Logs:
            - Modify the script to log events to a file for troubleshooting.
            Add this line inside $action:
            Add-Content -Path "C:\Scripts\MonitorFileCopy.log" -Value "Change detected at $(Get-Date). File copied."

    FINAL THOUGHTS
    **************
        Script Location:
            - Store scripts in a secure location like C:\Scripts to
            prevent unauthorized modification.
        Scheduled Task:
            - Task Scheduler ensures the script runs after reboot without requiring user intervention.
        Testing:
            - Periodically test the script to verify functionality.

        From experience, with these steps, the FileSystemWatcher script 
        /should/ reliably monitor changes and survive reboots, ensuring
        automated file copying remains operational.

.NOTES
2024-12-16:[UPDATES]
    Rewrite to leverage FileSystemWatcher instead of Robocopy.
    FSW is a .NET object available in PowerShell, and allows the
    script to react immediately to changes, rather than polling
    as it is event-driven, only triggers when the file changes,
    and reacts instantly to LastWrite updates.

2024-12-16:[CREATED]
    Let the troubleshooting and fun begin.
#>

# Define source and destination paths
$SourceFile = "C:\Planning Report Data Sources\report.xlsx"  # Replace with your source file
$DestinationFolder = "E:\Planning Report Data Sources"       # Replace with your destination folder

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

# Keep the script alive indefinitely
while ($true) { Start-Sleep -Seconds 1 }