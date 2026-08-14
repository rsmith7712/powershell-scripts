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
    Get-PsVersionFromDomainSystems.ps1

.DESCRIPTION
    Reports the PowerShell version of each domain server by remotely querying PSVersionTable.

.FUNCTIONALITY
    Reports PowerShell version across domain servers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Import-Module ActiveDirectory

#$ServerList = (Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -Like "* Server *"} -property Enabled,OperatingSystem).Name
$ServerList = (Get-ADComputer -Filter * -SearchBase "OU=Domain Controllers,DC=Domain,DC=com").Name #For Testing

ForEach ($Server in $ServerList)
{
    if(test-connection $Server -Count 2 -Quiet )
    {
        $PSVersion = "$(Invoke-Command -Computer $Server -ScriptBlock { $PSVersionTable.PSVersion.Major })"
        Write-Verbose "$($Server) : $($Server.operatingsystem) : $PSVersion"
        new-object -TypeName PSObject -Property @{Name=$Server;OS=$Server.operatingsystem;PSVersion=$PSVersion}
    }
    else
    {
        Write-Verbose "$($Server) : Unable to connect";
    }
} $Results | export-csv "C:\temp\PSVersion-$(get-date -format yyyy-MM-dd).csv" -NoTypeInformation
