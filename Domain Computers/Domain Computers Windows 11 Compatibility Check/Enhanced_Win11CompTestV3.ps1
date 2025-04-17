#Requires -Version 5.1
# LEGAL
<# LICENSE
    MIT License, Copyright 2025 Richard Smith

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
    Enhanced_Win11CompTestV3.ps1

.SUMMARY
    Checks the computer if is capable of upgrading to Windows 11.

.DESCRIPTION
  Deployment Script for Windows 11 Compatibility Check.
  This script will:
    1. Read a list of computer names.
    2. Copy a working compatibility-check script to each remote computer.
    3. Create and run a scheduled task on each remote computer to execute the script locally.
    4. Wait for the tasks to run and then copy the resulting output file back to a central share.
    
  Prerequisites: 
    - Administrative rights on remote computers.
    - SMB access (via the C$ share) to each remote computer.
    - Scheduled Tasks can be created remotely.
    - The compatibility-check script (this script file) is fully functional when run locally.
    
  Adjust the paths below as needed.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts


# Define directories and file paths
$destFolder    = "C:\temp\Enhanced_Win11CompTestV3"
$logPath       = Join-Path $destFolder "log_win11CompTestV3.txt"
$resultsPath   = Join-Path $destFolder "results_win11CompTestV3.csv"
$computersFile = "C:\temp\ComputerList_Validation\validated_Computers_Online_v2.txt"
#>

#region Variables and Setup

# Path to the computer list (one computer name per line)
$computersFile = "C:\temp\ComputerList_Validation\validated_Computers_Online_v2.txt"

# Folder on local computer where the results will be collected
$centralResultsFolder = "\\rsmith-lt01\results"

# Local path of the compatibility-check script that needs to be deployed.
# (Assumes this current script file is the working version.)
$localScriptPath = $MyInvocation.MyCommand.Path

# Remote folder in which to copy the script and where results will be saved
$remoteFolder = "C:\temp\Win11CompTestV3"
$remoteScriptName = "Enhanced_Win11CompTestV3.ps1"
# The result file that the compatibility-check script produces on the remote machine:
$resultFileName = "results_win11CompTestV3.csv"

# Name of the scheduled task to create on remote computers
$scheduledTaskName = "Run_Win11CompTest"

#endregion Variables and Setup

#region Read Computer List

try {
    $computerList = Get-Content -Path $computersFile -ErrorAction Stop | Where-Object { $_ -and $_.Trim() -ne "" }
    if ($computerList.Count -eq 0) {
        Write-Error "No computer names found in $computersFile. Exiting."
        exit
    }
}
catch {
    Write-Error "Failed to read computer list from $computersFile: $($_.Exception.Message)"
    exit
}

#endregion Read Computer List

#region Process Each Computer

foreach ($computer in $computerList) {
    $computer = $computer.Trim()
    Write-Output "Processing computer: $computer"
    
    try {
        # Define remote UNC path for the target folder: \\<computer>\C$\temp\Win11CompTestV3
        $remoteUncFolder = "\\$computer\C$\temp\Win11CompTestV3"
        
        # Create the remote folder if it does not exist.
        if (!(Test-Path -Path $remoteUncFolder)) {
            Write-Output "Creating remote folder on $computer: $remoteUncFolder"
            New-Item -Path $remoteUncFolder -ItemType Directory -Force | Out-Null
        }
        
        # Copy the local compatibility-check script to the remote folder.
        $remoteScriptPath = Join-Path $remoteUncFolder $remoteScriptName
        Write-Output "Copying script to $computer: $remoteScriptPath"
        Copy-Item -Path $localScriptPath -Destination $remoteScriptPath -Force
        
        # Set scheduled task parameters.
        # Use the remote local path for the script.
        $taskAction = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"C:\temp\Win11CompTestV3\$remoteScriptName`""
        
        # Determine start time as current time + 1 minute (format HH:mm).
        $startTime = (Get-Date).AddMinutes(1).ToString("HH:mm")
        
        Write-Output "Creating scheduled task on $computer to run at $startTime"
        # Create the scheduled task on the remote computer.
        # Use schtasks.exe with the /S parameter to specify the target computer.
        $schtaskCreateCmd = "schtasks /Create /S $computer /TN $scheduledTaskName /TR `"$taskAction`" /SC ONCE /ST $startTime /RL HIGHEST /F"
        Write-Output "Executing: $schtaskCreateCmd"
        Invoke-Expression $schtaskCreateCmd
        
        # Optionally, you may trigger the task immediately. Uncomment the next two lines if desired.
        Write-Output "Running scheduled task on $computer"
        $schtaskRunCmd = "schtasks /Run /S $computer /TN $scheduledTaskName"
        Invoke-Expression $schtaskRunCmd
        
    }
    catch {
        Write-Error "Error processing $computer: $($_.Exception.Message)"
    }
}

#endregion Process Each Computer

#region Wait for Remote Tasks to Complete

# Wait long enough for all remote tasks to complete.
# Adjust the sleep time as needed (in seconds). Here, we wait 3 minutes.
Write-Output "Waiting 3 minutes for remote tasks to complete..."
Start-Sleep -Seconds 180

#endregion Wait for Remote Tasks to Complete

#region Collect Results from Remote Computers

foreach ($computer in $computerList) {
    $computer = $computer.Trim()
    Write-Output "Collecting results from $computer..."
    
    $remoteUncFolder = "\\$computer\C$\temp\Win11CompTestV3"
    $remoteResultPath = Join-Path $remoteUncFolder $resultFileName
    $localResultDest = Join-Path $centralResultsFolder ("{0}_results.csv" -f $computer)
    
    try {
        if (Test-Path -Path $remoteResultPath) {
            Write-Output "Copying results from $computer"
            Copy-Item -Path $remoteResultPath -Destination $localResultDest -Force
        }
        else {
            Write-Warning "Result file not found on $computer at $remoteResultPath"
        }
    }
    catch {
        Write-Error "Error copying results from $computer: $($_.Exception.Message)"
    }
}

#endregion Collect Results from Remote Computers

Write-Output "Deployment and collection complete. Results saved to $centralResultsFolder"
