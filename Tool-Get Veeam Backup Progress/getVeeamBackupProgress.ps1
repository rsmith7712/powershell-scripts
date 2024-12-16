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
    getVeeamBackupProgress.ps1

.SYNOPSIS
    PowerShell script to actively monitor running veeam backup progress

.FUNCTIONALITY
    Load Veeam PowerShell Snap-In:
        -The script first loads the Veeam PowerShell Snap-In, which provides
        the necessary cmdlets to interact with Veeam Backup & Replication.
    Connect to Veeam Server:
        -Connect to your Veeam Backup & Replication server using the
        Connect-VBRServer cmdlet, replacing <YourVeeamServer> with the actual
        server name or IP address.
    Get-JobProgress Function:
        -This function takes the job name as input and retrieves the latest
        session information for that job. It then outputs the job name,
        status, and progress percentage.
    Monitor Loop:
        -The script enters a loop that continuously monitors the specified
        job. It calls the Get-JobProgress function and then sleeps for 30
        seconds before checking again. 

    How to use:
        -Save: Save the script as a .ps1 file.
        -Modify: Replace "YourBackupJobName" with the actual name of the Veeam
            backup job you want to monitor.
        -Run: Execute the script in PowerShell. It will continuously monitor the
            job and output its progress. 

Enhancements:
    Multiple Jobs: Modify the script to monitor multiple jobs by adding them to an array and iterating over them.
    Logging: Add logging capabilities to the script to record job progress to a file.
    Notifications: Implement email or other notifications to alert you when a job fails or completes. 

.NOTES
#>

# Load the Veeam PowerShell Snap-In
Add-PSSnapin VeeamPSSnapIn

# Connect to Veeam Backup & Replication Server
Connect-VBRServer -Server "SYMUTILITY.corp.symetrix.co"

# Function to get job progress
function Get-JobProgress {
    param(
        [Parameter(Mandatory = $true)]
        [string]$JobName
    )
    $job = Get-VBRJob -Name $JobName
    if ($job) {
        $session = Get-VBRSession -Job $job | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
        if ($session) {
            $progress = $session.Progress
            Write-Output "Job: $JobName, Status: $($session.State), Progress: $($progress.Percent)%"
        }
        else {
            Write-Output "Job: $JobName, No active session found."
        }
    }
    else {
        Write-Output "Job: $JobName, Not found."
    }
}
# Example usage
while ($true) {
    Get-JobProgress -JobName "YourBackupJobName"
    Start-Sleep -Seconds 10
}