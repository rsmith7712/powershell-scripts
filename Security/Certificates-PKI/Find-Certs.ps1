# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Find-Certs.ps1

.DESCRIPTION
    Queries Windows servers in Active Directory for local-machine certificates expiring within 180 days.

.FUNCTIONALITY
    Reports soon-to-expire certificates across servers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$ErrorActionPreference = "SilentlyContinue"

Invoke-Command -ComputerName (get-adcomputer -LDAPFilter "(&(objectCategory=computer)(operatingSystem=Windows Server*)(!serviceprincipalname=*MSClusterVirtualServer*)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" -Property name | sort-object Name).Name -Command {
   get-childitem cert:LocalMachine\My -recurse | where-object {$_.notafter -le (get-date).AddDays(180) -AND $_.notafter -gt (get-date)} | select Subject,FriendlyName,Thumbprint,@{Name='Expires in (Days)';Expression={($_.NotAfter).subtract([DateTime]::Now).days}}
  }