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
    EnableRemoteRegistry.ps1

.DESCRIPTION
    Enables and starts the Remote Registry service on every reachable Active Directory computer.

.FUNCTIONALITY
    Enables the Remote Registry service across AD computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

cls 
$computers = Get-ADcomputer -Filter * 
foreach ($computer in $computers) 
{ 
    if (Test-Connection -count 1 -computer $computer.Name -quiet){ 
    Write-Host "Updating system" $computer.Name "....." -ForegroundColor Green 
    Set-Service –Name remoteregistry –Computer $computer.Name -StartupType Automatic 
    Get-Service remoteregistry -ComputerName $computer.Name | start-service 
} 
    else 
    { 
        Write-Host "System Offline " $computer.Name "....." -ForegroundColor Red 
        echo $computer.Name >> C:\temp\Inventory\offlineRemoteRegStartup.txt} 
    }