# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Deploy-Task.ps1

.DESCRIPTION
    Deploys a scheduled task, with a logging helper function.

.FUNCTIONALITY
    Deploys a scheduled task.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Append-Log
{
param
(
    [parameter(Mandatory=$true,Position=0)][string]$message,
    [parameter(Mandatory=$false,Position=1)][string]$color = "White"
)
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=======================================[ End Function ]==========================================
Function Deploy-Task
{
param
(
    [parameter(Mandatory=$true,Position=0)][string]$tHostname,
    [parameter(Mandatory=$true,Position=1)][string]$tName,
    [parameter(Mandatory=$true,Position=2)][string]$tRun,
    [parameter(Mandatory=$true,Position=3)][string]$tStart,
    [parameter(Mandatory=$true,Position=4)][string]$tSchedule,
    [parameter(Mandatory=$true,Position=5)][string]$tRunas,
    [parameter(Mandatory=$true,Position=6)][string]$tRunasPw
)
    try
    {    
        SCHTASKS /CREATE /F /s $tHostname /TN $tName /RU $tRunas /RP $tRunasPw  /SC $tSchedule /ST $tStart /TR $tRun
        $statuscode = $LASTEXITCODE
        if(!($statuscode -eq 0))
        {
            $status = "[ERROR] : Scheduled Backup task could not be created on $tHostname.";$color = "Red"
        }
            else
            {
                $status = "[SUCCESS] : Scheduled Backup task successfully created on $tHostname.";$color = "Green"
            }
    }
        catch 
        {
            $status = "[EXCEPTION] : Scheduled task could not be created on $tHostname. Exception Message: $($_.Exception.Message).";$color = "Cyan"
        }
        Append -message $status -color $color
}#===================[End Function]===================
#######################################[SCRIPT STARTS]########################################
Clear-Host
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
Append-Log -message "[BEGIN]"
#---------------------------------------------------------------------------------------------
$taskname = Check-SGVersion
$task = "powershell.exe -executionpolicy bypass -file C:\temp\Check-SGVersion.ps1"
$computerlist = Get-Content "C:\temp\computerlist.txt"
foreach($computer in $computerlist){
        Deploy-Task -tHostname $computer -tName $taskname -tRun $task -tStart "1:00" -tSchedule "Daily" -tRunas "domain\orgsvc" -tRunasPw "<password>"
}
#---------------------------------------------------------------------------------------------
# Clean up and exit
$elapsed = [math]::Round($stopwatch.Elapsed.TotalMinutes,2)
$stopwatch.Stop()
Append-Log -message "[END] : Script Completion. TTC = $($elapsed) Minutes."
EXIT
#########################################[SCRIPT END]#########################################