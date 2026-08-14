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
    Check-Status-RemoteRegistry.ps1

.DESCRIPTION
    Checks the Remote Registry service status on a server (with a commented-out option to start it via alternate credentials).

.FUNCTIONALITY
    Checks the Remote Registry service on a server.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



#Option1
Get-WmiObject -Class Win32_Service -ComputerName SRVWINFS01P.example.com -Filter "Name='RemoteRegistry'"

<#
#Option2
$svc = Get-WmiObject -Class Win32_Service -ComputerName SRVWINFS02P.example.com -Filter "Name='RemoteRegistry'" -ErrorAction SilentlyContinue -Credential $altcreds
if (-not $svc){
  "Cannot connect to SRVWINFS02P.example.com."
  exit 1
}
if ($svc.State -eq 'Stopped') {$svc.StartService()}
Get-WmiObject -Class Win32_Service -ComputerName SRVWINFS02P.example.com -Filter "Name='RemoteRegistry'"
#>

<#
#Option3
Invoke-Command -ComputerName SRVWINFS01P.example.com -ScriptBlock {
    Get-Service 'RemoteRegistry' | Where-Object { $_.State -eq 'Stopped' } | Start-Service
  } -Credential $altcreds
#>
