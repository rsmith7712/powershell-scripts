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
    Kill-MSAccess.ps1

.DESCRIPTION
    Finds store computer objects via ADSI and terminates the Microsoft Access process on the matched machines.

.FUNCTIONALITY
    Kills the MS Access process on store computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


Function Get-ADSIStoreComputerObjects($store,$ou)
{

    $objSearcher = New-Object DirectoryServices.DirectorySearcher
    $objSearcher.Filter = "(&(objectCategory=Computer)(|(Name=$store*s*)(Name=$store*j*)))"
    $objSearcher.SearchRoot = "LDAP://$OU"
    $objSearcher.PageSize = 1000
    $objComputer = $objSearcher.FindAll()
    foreach ($obj in $objComputer){
        $LDAPPath = [ADSI]$obj.path
        $computer = $LDAPPath.Name
        $online = (Test-NetConnection -ComputerName $computer).PingSucceeded
        if($online){Write-Host "$computer is Online" -ForegroundColor Magenta}
        }
}
    [string]$store = $env:COMPUTERNAME.Substring(0,4)
    $ou = "OU=Store Computers,DC=DOMAIN,DC=com"
    Get-ADSIStoreComputerObjects -store $store -ou $ou

    function Stop-Access{
    append_log "Stopping currently running MSACCESS processes."
    # Attempts to gracefully close Access.
    Get-Process MSACCESS | Foreach-Object { $_.CloseMainWindow() | Out-Null }
    }