# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    add_dnsentry.ps1

.SYNOPSIS
  Function used to add DNS entry to DNS server

.EXAMPLE
  add_dnsentry -HostName "FQDN" -IP "0.0.0.0"

.FUNCTIONALITY
    Function used to add DNS entry to DNS server

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function add_dnsentry
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $HostName,
    
        [parameter(Mandatory=$true,
        Position=1)]
        $IP
    )

    $DC = "SRV-ADS-DC16"
    $adddnsrecord = 
    {
        $IP = $args[0]
        $HostName = $args[1]
        Add-DnsServerResourceRecord -ZoneName "example.com" -IPv4Address $IP -A -TimeToLive "01:00:00" -Name $HostName
    }
    $removednsrecord = 
    {
        $Hostname = $args[0]
        Get-DnsServerResourceRecord -ZoneName "example.com" | Where-Object {$_.HostName -eq "$($HostName)"} | Remove-DnsServerResourceRecord -Force -ZoneName "example.com"
    }

    #checks to see if entry needs to be modified or created
    $existingEntries = invoke-command -scriptblock {Get-DnsServerResourceRecord -ZoneName example.com} -ComputerName $DC -Credential $script:credential | Where-Object {$_.HostName -eq "$($HostName)"}

    if(($existingEntries.HostName) -eq $Null)
    {
        Invoke-Command -ComputerName $DC -ScriptBlock $adddnsrecord -ArgumentList $IP,$HostName -Credential $script:credential
        if($?)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    else 
    {
        Write-Host "Existing DNS entries found for $($hostname), removing before continuing." -ForegroundColor Yellow
        Log_ToSplunk -Message "Existing DNS entries found for $($hostname), removing before continuing."
        Invoke-Command -ComputerName $DC -ScriptBlock $removednsrecord -ArgumentList $HostName -Credential $script:credential
        if($?)
        {
            Log_ToSplunk -Message "Existing DNS entries removed for $($hostname)"
            Write-Host "Existing DNS entries removed for $($hostname), proceeding to create new entry"

            Invoke-Command -ComputerName $DC -ScriptBlock $adddnsrecord -ArgumentList $IP,$HostName -Credential $script:credential
            if($?)
            {
                return $true
            }
            else
            {
                return $false
            }
        }
    }
}