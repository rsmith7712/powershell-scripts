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
    Watch-Process.ps1

.DESCRIPTION
    Registers a WMI event that logs each process as it starts.

.FUNCTIONALITY
    Watches for process starts via WMI event.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

##New Process
$WMI = @{
    Query = "select * from Win32_ProcessStartTrace"
    Action = {
        Write-Host ("Process: {0}({1}) started at {2}" -f $event.SourceEventArgs.NewEvent.ProcessName,
                                                        $event.SourceEventArgs.NewEvent.ProcessID,
                                                        [datetime]::FromFileTime($event.SourceEventArgs.NewEvent.TIME_CREATED)) -Back Black -Fore Green
    }
    SourceIdentifier = "Process.Created"
}
$Null = Register-WMIEvent @WMI
 
##Process End
$WMI = @{
    Query = "select * from Win32_ProcessStopTrace"
    Action = {
        Write-Host ("Process: {0}({1}) was terminated at {2}" -f $event.SourceEventArgs.NewEvent.ProcessName,
                                                                $event.SourceEventArgs.NewEvent.ProcessID,
                                                                [datetime]::FromFileTime($event.SourceEventArgs.NewEvent.TIME_CREATED)) -Back Black -Fore Yellow
    }
    SourceIdentifier = "Process.Deleted"
}
$Null = Register-WMIEvent @WMI
# get-eventsubscriber | unregister-event