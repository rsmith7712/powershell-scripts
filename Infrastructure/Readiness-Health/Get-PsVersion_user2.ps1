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
    Get-PsVersion_user2_v1.ps1

.DESCRIPTION
    Enumerates computers in a server OU via ADSI to collect PowerShell version and status (variant).

.FUNCTIONALITY
    Reports PowerShell version across an OU (ADSI).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Get-ADComputerStatus_user2_v1.ps1

#$OU = "OU=Domain Controllers,DC=Domain,DC=com"
$OU = "OU=Domain Servers,DC=Domain,DC=com"

$objSearcher = New-Object DirectoryServices.DirectorySearcher
$objSearcher.Filter = '(objectCategory=Computer)'
$objSearcher.SearchRoot = "LDAP://$OU"
$objSearcher.PageSize = 1000

$objComputers = $objSearcher.FindAll()

$objComputers | Foreach{
        $LDAPPath = [ADSI]$_.path
        $Server = $LDAPPath.Name
        $OS = $LDAPPath.operatingSystem
    

    if(test-connection -computername $Server -Count 2 -Quiet ){
            $PSVer = Invoke-Command -ComputerName $Server -ScriptBlock {$PSVersionTable.PSVersion.Major}
            Write-Host "$Server : $PSVer : $OS"
            $Results = New-Object -TypeName PSObject -Property @{Name="$Server";PSVersion=$PSVer;OSVersion="$OS"}
        }
    else
        {
            Write-Host "$Server : Unable to connect"
        }

$timestamp = (get-date).tostring("yyyy-MM-dd")
$Results | Export-CSV "C:\temp\PSVersion_$timestamp.csv" -NoTypeInformation -Append.
}