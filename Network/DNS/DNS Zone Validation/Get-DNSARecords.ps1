# LEGAL
<# LICENSE
    MIT License, Copyright 2021 Richard Smith

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
    Get-DNSARecords.ps1

.DESCRIPTION
    Dumps A Records from a Microsoft Windows DNS server.

.FUNCTIONALITY
    This script dumps the conent of MicrosoftDNS_AType to a CSV file.

    .PARAMETER Server
        The name of the Computer you want to run the command against.
    .PARAMETER CSVPath
        The location and filename of a file to save the output to (defaults to .\dns.csv).
    .PARAMETER UserName
        Username to authenticate to the server with (optional). If not supplied, the current user context is used.
        **If a username is supplied -Password must also be provided.**
    .PARAMETER Password
        Password to use for authentication (optional).
    .EXAMPLE
        Get-DNSARecords -Server 192.168.1.1 -CSVPath c:\temp\dns.csv -UserName DOMAIN\Administrator -Password Password123
    .EXAMPLE
        Get-DNSARecords -Server 192.168.1.1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

    https://gist.github.com/blark/510cc216416a6160d703bedc7f880b4b

#>

function Get-DNSARecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$Server,
        [string]$CSVPath="dns.csv",
        [string]$UserName,
        [string]$Password
    )
    # Set up a hash table to store parameters for Get-WmiObject
    $params=@{'Class'='MicrosoftDNS_AType'
              'NameSpace'='Root\MicrosoftDNS'
              'ComputerName'=$Server
    }
    if ($UserName -and $Password) {
    # Convert username:password to credential object
        $SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $Credentials = New-Object -Typename System.Management.Automation.PSCredential -ArgumentList $UserName, $SecPassword
        $params.Add("Credential", $Credentials)
    }
    Write-Output "Acquiring MicrosoftDNS_AType WmiObject..."
    $dnsRecords = Get-WmiObject @params | Select-Object -Property OwnerName,RecordData,@{n="Timestamp";e={([datetime]"1.1.1601").AddHours($_.Timestamp)}}
    Write-Output ("Found *{0}* records." -f $dnsRecords.Count)
    Write-Output ("Writing to {0}..." -f $CSVPath)
    $dnsRecords | Export-CSV -not $CSVPath
    Write-Output "Done."
}