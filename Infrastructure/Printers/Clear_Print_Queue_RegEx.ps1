# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Clear_Print_Queue_RegEx.ps1

.DESCRIPTION
            This script clears the print queue of the targeted computer, stops the spooler service, removes the printer and restarts the computer.

.FUNCTIONALITY
            This script clears the print queue of the targeted computer, stops the spooler service, removes the printer and restarts the computer.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#$computername = Read-Host "Enter Computer Name"

Do
{
    Clear-Host
    If ($Count -ge 1)
    {
        Write-Host "Computer is not a tag machine, please try again." -ForegroundColor Red
    }
    $computer = Read-Host "Enter Computer Name"
    If ($computer.substring(4,3) -ne "tag")
    { 
        $Test = $False
    }
    Else
    { 
        $RegEx = [RegEx]::IsMatch($computer,"\d{4}[tTaAgG]{3}\d{2}")
        If($RegEx -eq $True)
        {
            $Test = $True
        }
        else 
        {
            $Test = $False
        }    
     }
    $Count++
}
While ($Test -ne $True)

$printerinfo = Get-WmiObject -Class win32_printer -ComputerName $computer

#tests connection to computer
if(!(Test-Connection $computer -Quiet))
{
    write-host "$computer offline"
    continue
}
else
{
    if ($printerinfo)
    {
        try
        {
            Write-Host "Cancelling Print Job(s)"
            $printerinfo | foreach{$_.CancelAllJobs()}
            Clear-Host
            Start-Sleep -Seconds 2
            $printerinfo | foreach{$_.Delete()}
            Clear-Host
            Start-Sleep -Seconds 2
            Restart-Computer -ComputerName $computer -Force
            Write-Host "Cancelled Print Job(s), removed printer driver and rebooted machine."
        }
        catch
        {
            Write-Host "Failed to cancel jobs"
        }
    }
    Else
    {
        Write-Host "No Printer Installed."
    }
}
