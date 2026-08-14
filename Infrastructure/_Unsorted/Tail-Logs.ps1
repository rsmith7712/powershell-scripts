# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    Tail-Logs.ps1

.SYNOPSIS
  Follows (tails) a log file in real time via powershell prompt.

.EXAMPLE
 Tail-Log -action "start" -logs $script:logFile

.FUNCTIONALITY
    Follows (tails) a log file in real time via powershell prompt.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Tail-Log ($action,$logs)
{
    if(Test-Path $logs -ErrorAction SilentlyContinue)
    {
        switch($action)
        {
            "start"
            {
                $args = "get-content",$logs,"-Wait"
                $script:pspid = (Start-Process "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -ArgumentList $args -PassThru).Id
            }
            "stop"
            {
                Stop-Process -Id $script:pspid
            }
        }
    }
    else
    {
        Write-Host "Log file location was not found.  Please verify the log file path, and enter it using the '-logs' switch." -ForegroundColor Yellow
        Write-Host "Exiting in 10 seconds..."
        Start-Sleep -Seconds 10
        Exit 1
    }
}
####################################
# /////-----[Script Begin]-----\\\\\
####################################
$script:logFile = "C:\temp\NextGen\TicketingSetup.Log"
Tail-Log -action "start" -logs $script:logFile
####################################
# \\\\\-----[Script End]------/////
####################################