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
    np-test-6.ps1

.DESCRIPTION
    Connects to an on-premises Exchange session and exports each distribution group's members to a text file (test).

.FUNCTIONALITY
    Exports distribution-group membership (test).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
Get-DistributionGroup :: is an EXCHANGE cmdlet.

You need to install the Exchange Management Tools,
or connect to a management session on an Exchange server.
#>
Import-module ActiveDirectory
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://srvexmb01.example.com/PowerShell/ -Authentication Kerberos
Import-PSSession $Session -AllowClobber
$sb1 = {
    $saveto = "C:\temp\listmembers.txt"
        Get-DistributionGroup | Sort-Object Name | ForEach-Object{
            "`r`n$($_.Name)`r`n=============" | Add-Content $saveto
        Get-DistributionGroupMember $_ | Sort-Object Name | ForEach-Object{
		    If($_.RecipientType -eq "UserMailbox"){
				    $_.Name + " (" + $_.PrimarySMTPAddress + ")" | Add-Content $saveto
	}}} Get-DistributionGroup >> C:\temp\Groups.txt}
Invoke-Command -ScriptBlock {$sb1} -ComputerName "SRVEXMB01"