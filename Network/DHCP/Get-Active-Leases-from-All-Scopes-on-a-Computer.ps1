# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
   Get-Active-Leases-from-All-Scopes-on-a-Computer.ps1

.SYNOPSIS
    - Get-Active-Leases-from-All-Scopes-on-a-Computer
    - Break out on individual lines per audit policy
    - Obtain written approval prior to execution against IC privack sources

.FUNCTIONALITY
    Prompts for Input

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Get-Active-Leases-from-All-Scopes-on-a-Computer

Get-DhcpServerv4Scope -ComputerName "SVR.DOMAIN.gov" | Get-DhcpServerv4Lease -ComputerName "SVR.DOMAIN.gov" | Export-Csv e:\logs\SVR.DOMAIN.gov-DHCP-Scopes-and-Active-Leases.csv -NoTypeInformation

Get-DhcpServerv4Scope -ComputerName "SVR.DOMAIN.gov" | Get-DhcpServerv4Lease -ComputerName "SVR.DOMAIN.gov" | Export-Csv e:\logs\SVR.DOMAIN.gov-DHCP-Scopes-and-Active-Leases.csv -NoTypeInformation

Get-DhcpServerv4Scope -ComputerName "SVR.DOMAIN.gov" | Get-DhcpServerv4Lease -ComputerName "SVR.DOMAIN.gov" | Export-Csv e:\logs\SVR.DOMAIN.gov-DHCP-Scopes-and-Active-Leases.csv -NoTypeInformation

Get-DhcpServerv4Scope -ComputerName "SVR.SUB.DOMAIN.gov" | Get-DhcpServerv4Lease -ComputerName "SVR.SUB.DOMAIN.gov" | Export-Csv e:\logs\SVR.SUB.DOMAIN.gov-DHCP-Scopes-and-Active-Leases.csv -NoTypeInformation

Get-DhcpServerv4Scope -ComputerName "SVR.SUB.DOMAIN.gov" | Get-DhcpServerv4Lease -ComputerName "SVR.SUB.DOMAIN.gov" | Export-Csv e:\logs\SVR.SUB.DOMAIN.gov-DHCP-Scopes-and-Active-Leases.csv -NoTypeInformation

Get-DhcpServerv4Scope -ComputerName "SVR.SUB.DOMAIN.gov" | Get-DhcpServerv4Lease -ComputerName "SVR.SUB.DOMAIN.gov" | Export-Csv e:\logs\SVR.SUB.DOMAIN.gov-DHCP-Scopes-and-Active-Leases.csv -NoTypeInformation

Get-DhcpServerv4Scope -ComputerName "SVR.SUB.DOMAIN.gov" | Get-DhcpServerv4Lease -ComputerName "SVR.SUB.DOMAIN.gov" | Export-Csv e:\logs\SVR.SUB.DOMAIN.gov-DHCP-Scopes-and-Active-Leases.csv -NoTypeInformation