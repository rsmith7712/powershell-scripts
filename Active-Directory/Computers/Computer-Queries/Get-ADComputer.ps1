# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    Get-ADComputer.ps1

.DESCRIPTION
    Iterates all Active Directory computers, tests connectivity, and reports whether a specific Group Policy registry value is set on each reachable machine.

.FUNCTIONALITY
    Checks a GPO registry value across AD computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Get-ADComputer -Filter * | Select -Expand Name |
% {
  if (Test-Connection $_ -Count 1 -Quiet)
  {
    $result = Invoke-Command -Computer $_ -ScriptBlock { Get-GPRegistryValue -Name '5minutes Policy' -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' -ea SilentlyContinue }
    $state = 'GPO ' + 'not ' * ($result -eq $null) + 'set'
  } else {
    $state = 'not reachable'
  }
  [PSCustomObject] @{computername = $_; state = $state }
}