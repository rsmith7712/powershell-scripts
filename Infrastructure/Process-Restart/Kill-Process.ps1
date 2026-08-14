# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Kill-Process_2.ps1

.SYNOPSIS
  Function to monitor for, and stop processes started after this function is called.
 
.DESCRIPTION
  Kill-Process will begin monitoring for a specified process to start via Register-WMIEvent query, and then use the 'Stop-Process' function to kill it.

.EXAMPLE
  In most cases the process executable and name are the same (e.g., notepad.exe and notepad), in which case only the process name need be specified in this function:

      Kill-Process -PN "notepad"
  
  If the processname and process executable file name differ, then the following syntax is necessary:

      Kill-Process -PN "notepad" -ProcessExecutable "notepad.exe"
  
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  05/22/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (05/22/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Kill-Process will begin monitoring for a specified process to start via Register-WMIEvent query, and then use the 'Stop-Process' function to kill it.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Kill-Process
{
 [CmdletBinding()]
 Param
 (
   [alias("PN")]
   [parameter(Mandatory=$true,
   Position=0)]
   [string]$script:ProcessName,

   [parameter(Mandatory=$false,
   Position=1)]
   $ProcessExecutable = $script:ProcessName + ".exe"
 )
        Get-EventSubscriber | Unregister-Event
        $query = "Select * from win32_ProcessStartTrace where Processname='$ProcessExecutable'"
        $action = {
                    Stop-Process -ProcessName "$ProcessName"
                    Write-Host "$ProcessName Killed!"
                  }

        Register-WmiEvent -Query $query -Action $action
}
Kill-Process -PN "notepad" -ProcessExecutable "notepad.exe"