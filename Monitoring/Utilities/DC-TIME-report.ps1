# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
    DC-TIME-report.ps1

.DESCRIPTION
    Reports the configured time source of each domain controller (via w32tm) to a log.

.FUNCTIONALITY
    Reports domain-controller time sources.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function CheckTimeServers {
BEGIN {}
PROCESS {
$Server = "$_"
if ($_ -ne "") {
Write-host "Checking time source of $Server, pasting output in $($LogFile)"
$TimeServer = w32tm /query /computer:$Server /source
Write-output "[$(Get-Date -format g)]: Server $($Server) gets its time from $($TimeServer)" >> $LogFile
}
}
END {}
}
cls
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
$LogFile = $Scriptpath+"c:\temp\Output.txt"
Get-Content $Scriptpath"c:\temp\ServerList.txt" | CheckTimeServers