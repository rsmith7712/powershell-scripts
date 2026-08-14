# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    Restart-Host.ps1

.DESCRIPTION
    Restarts a computer and waits for it to come back online within a specified timeout.

.FUNCTIONALITY
    Restarts a computer and waits for it.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

param(
    [string]$computer = $(throw "Requires -computer 'computername'")
)
Function Restart-Host($computer,$timeout)
{
  $output = "$computer - Rebooting computer. Time-out limit: $($timeout) seconds."
  Write-Host $output -ForegroundColor Yellow
    Try
    {    
        Restart-Computer -ComputerName $computer -Wait -For Wmi -Timeout $timeout -ErrorAction Stop
        $output = "SUCCESS: $computer Rebooted Successfully within the specified time-out period of $($timeout) seconds."
    }
        Catch
        {
            $output = "WARNING: $computer reboot failure. Timeout period $($timeout) seconds. Exception Message: $($_.Exception.Message)."
        }
    Return $output
}#---------[END Function]---------
Function Get-Uptime($computer)
{
    Try
    {
        $boot = Get-WmiObject -ComputerName $computer -Class win32_operatingsystem -ErrorAction Stop
        $rebooted = $boot.converttodatetime($boot.lastbootuptime)
        $difference = ((Get-Date) - $rebooted)
        $days = $difference.Days
        $hours = $difference.Hours
        $minutes = $difference.Minutes
        $seconds = $difference.Seconds
        $output = "$computer UPTIME:Days:$days Hours:$hours Minutes:$minutes Seconds:$seconds"
    }
        Catch
        {
            $output = "Unable to query WMI on $computer for LastBootupTime. Exception Message: $($_.Exception.Message)"
        }
    Return $output
}#---------[END Function]---------

# ///////////// Script Starts \\\\\\\\\\\\\
    Clear-Host
    $timeout = 180
    $rebootstatus = Restart-Host -computer $computer -timeout $timeout
    $uptime = Get-Uptime -computer $computer
    Write-Host $rebootstatus $uptime -ForegroundColor Yellow

# \\\\\\\\\\\\\\ Script Ends //////////////