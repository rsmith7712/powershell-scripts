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
    Find-FolderChanges.ps1

.DESCRIPTION
    Captures folder permissions, network state (netstat) and running processes to help detect changes to a monitored folder.

.FUNCTIONALITY
    Captures folder ACL, network and process state for change detection.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$Count = 0
$Path = "C:\Reports"

Function Run-NetStat($FileName)
{
    & cmd.exe /c netstat.exe -b > C:\temp\folderchanges\$Filename`_Netstat.txt
}

function get_process($filename)
{
    Get-Process | Out-File C:\temp\folderchanges\$filename`_process.txt
}

Function Check-Permissions($FolderPath)
{
    $Check = Get-ACL $FolderPath
    If($($Check.Access.count) -lt 3)
    {
        Return $False
    }
    else 
    {
        Return $True    
    }
}

Do
{
    Start-Sleep 5
    $Count ++
    Run-NetStat $Count
    get_process $Count
    $Permissions = Check-Permissions $Path
}
While($Permissions -eq $True)

$Stamp = Get-Date -Format HH:mm:ss
Write-Host "Looks like the folder permissions changed at $Stamp. Take a look at $Count`_netstat.txt and the 3 or 4 previous logs."