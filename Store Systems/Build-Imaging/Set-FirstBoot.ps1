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
    Set-FirstBoot.ps1

.SYNOPSIS
  Ticketing First Boot
 
.DESCRIPTION
  Enables the recovery partition, creates symlink for Elo, turns off hibernate
 
.NOTES
  Version:        1.0
  Author:         user26
  Creation Date:  6/2/2016
  Purpose/Change: Initial Script Development.

.HISTORY

.FUNCTIONALITY
    Enables the recovery partition, creates symlink for Elo, turns off hibernate

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# ----------------------------------------------------------------------------------------------
# Initializations
$script:script_filepath = $MyInvocation.MyCommand.Path
$script:script_dir = Split-Path -Parent $script:script_filepath
$ErrorActionPreference = "SilentlyContinue"
# ----------------------------------------------------------------------------------------------
# Functions
Function Get_RegKey{
    $WinLogon = Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $FirstBoot = $WinLogon.FirstBoot
    return $FirstBoot
    }

Function Set_RegKey{
    $winlogon = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
    If(!($winlogon.FirstBoot)){ # Creates the FirstBoot string if it doesn't exist
        New-ItemProperty  -Path $winlogon -Name "FirstBoot" -PropertyType "String" -Value ''
        }
    Set-ItemProperty -Path $winlogon -Name "FirstBoot" -Value 1
    }
# ----------------------------------------------------------------------------------------------
# Script
$Check = Get_RegKey
If($env:USERNAME -ne "Setup"){
    Exit
    }
ElseIf($Check -eq 1){
    Exit
    }
#Creates Hidden Folder
$(MkDir "C:\Progra~1").Attributes = 'Hidden'
#Creates Symlink to Fix the screwup inside DomainGrade for Calibration
& "C:\Windows\System32\cmd.exe" /c mklink /j "C:\Progra~1\EloTou~1\" "C:\Program Files\Elo TouchSystems\"
#Enables Recovery Partition
& "C:\Windows\System32\ReAgentc.exe" /enable
#Ensures Hibernate is Off
& "C:\Windows\System32\powercfg.exe" -h off

Set_RegKey
Exit