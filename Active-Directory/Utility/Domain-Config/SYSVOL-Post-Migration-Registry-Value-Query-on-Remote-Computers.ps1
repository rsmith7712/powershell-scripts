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
    SYSVOL-Post-Migration-Registry-Value-Query-on-Remote-Computers.ps1

.DESCRIPTION
    Queries the SYSVOL DFSR migration 'Local State' registry value on remote computers to confirm FRS-to-DFSR migration.

.FUNCTIONALITY
    Checks SYSVOL DFSR migration state on remote computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Run from an Administrative PowerShell or Command Shell session
# Local State value (3) denotes FRS is Eliminated and SYSVOL replication is using only DFSR

#(invoke-command -ComputerName srv -ScriptBlock {Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating SysVols' -Name 'Local State' })
#(invoke-command -ComputerName srv -ScriptBlock {Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating SysVols' -Name 'Local State' })
#(invoke-command -ComputerName srv -ScriptBlock {Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating SysVols' -Name 'Local State' })
#(invoke-command -ComputerName srv -ScriptBlock {Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating SysVols' -Name 'Local State' })

#(invoke-command -ComputerName srv -ScriptBlock {Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating SysVols' -Name 'Local State' })
#(invoke-command -ComputerName srv -ScriptBlock {Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating SysVols' -Name 'Local State' })
#(invoke-command -ComputerName srv -ScriptBlock {Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating SysVols' -Name 'Local State' })
#(invoke-command -ComputerName srv -ScriptBlock {Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating SysVols' -Name 'Local State' })

#(invoke-command -ComputerName srv -ScriptBlock {Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating SysVols' -Name 'Local State' })

#(invoke-command -ComputerName srv -ScriptBlock {Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\DFSR\Parameters\SysVols\Migrating SysVols' -Name 'Local State' })
