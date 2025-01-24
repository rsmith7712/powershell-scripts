﻿# LEGAL
<# LICENSE
    MIT License, Copyright 2024 Richard Smith

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
.DESCRIPTION
  Query-ADComputers-for-NetAdapter-CN-Desc-Status-MAC-Speed.ps1

.FUNCTIONALITY
  - 

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
		
#>

$Computers = Get-ADComputer -Filter '*'

$Results = foreach ($Computer in $Computers) {
    if (Test-Connection -ComputerName $Computer.Name -Quiet -Count '1') {
        Invoke-Command -ComputerName $Computer.Name -ScriptBlock {
            $Adapters = Get-NetAdapter
            foreach ($Adapter in $Adapters) {
                [PSCustomObject]@{
                    'ComputerName' = $using:Computer.Name
                    'Name'        = $Adapter.Name
                    'Description' = $Adapter.InterfaceDescription
                    'Status'      = $Adapter.Status
                    'MacAddress'  = $Adapter.MacAddress
                    'Speed'       = $Adapter.LinkSpeed
                }
            }
        }
    }
    else {
        [PSCustomObject]@{
            'ComputerName' = $Computer.Name
            'Name'        = 'OFFLINE'
            'Description' = 'OFFLINE'
            'Status'      = 'OFFLINE'
            'MacAddress'  = 'OFFLINE'
            'Speed'       = 'OFFLINE'
        }
    }
}

$Results | Export-Csv -Path C:\Results\Reports\NetAdapters2.csv -NoClobber