# LEGAL
<# LICENSE
    MIT License, Copyright 2021 Richard Smith

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
    Get-IP-Address-From-Remote-Host-via-TextList.ps1

.DESCRIPTION
    Resolves the IP address of each server in a text list by pinging them.

.FUNCTIONALITY
    Resolves server IPs from a hostname list.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$Servers = Get-Content -path "C:\Temp\servers.txt"
$Array = @()
$ping = New-Object System.Net.NetworkInformation.Ping

#Looping each server
Foreach($Server in $Servers)
{
    $ServerIP = $null
    $Object = $null
    $Value = $null

    # Ping server
    $ServerIP = ($ping.Send($Server).Address)

    If($ServerIP)
    {
        $Value = $ServerIP.IPAddressToString
    }
    Else
    {
        $Value = "(not found)"
    }
    # Create object
    $Object = New-Object PSObject -Property ([ordered]@{
            Server                  = $Server
            IPAddress               = $Value
        })

    # Add object to array
    $Array += $Object

    #Display object
    $Object
}

If($Array)
{
    #Save CSV file with results
    $Array | Export-Csv -Path "C:\Temp\IPAddresses.csv" -NoTypeInformation
}
