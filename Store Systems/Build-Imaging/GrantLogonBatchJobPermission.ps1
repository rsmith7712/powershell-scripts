# LEGAL
<# LICENSE
    MIT License, Copyright 2019 Richard Smith

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
    GrantLogonBatchJobPermission.ps1

.SYNOPSIS
  Grants a Logon as a Batch Job user permission right to a service account 
 
.DESCRIPTION
  Does Stuf.
  
.NOTES
  Version:        1.0 
  Modified by:	  
  Creation Date:  03/28/2019
  Purpose/Change: Initial Script Development 

.HISTORY
  Version:        1.0 
  Author:         Tony Chu
  Modified by:	  
  Creation Date:  03/28/2019
  Purpose/Change: Initial Script Development
  Version:        1.0

.FUNCTIONALITY
    Does Stuf.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
$script:scriptFilepath = $MyInvocation.MyCommand.Path
$script:scriptDir = Split-Path -Parent $script:scriptFilepath
$errorActionPreference = "SilentlyContinue"
$Script:ProductName = "GrantLogonBatchJobPermission"
$script:ipScheme =
$accountToAdd = "DOMAIN\orgsvc"

# ----------------------------------------------------------------------------------------------
# Script Starts
# ----------------------------------------------------------------------------------------------

# Borrowed ideas from how to grant logon service account via https://gallery.technet.microsoft.com/scriptcenter/Grant-Log-on-as-a-service-11a50893 
if( [string]::IsNullOrEmpty($accountToAdd) ) {
	Write-Host "no account specified"
	exit
}

$sidstr = $null
try {
	$ntprincipal = new-object System.Security.Principal.NTAccount "$accountToAdd"
	$sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
	$sidstr = $sid.Value.ToString()
	} catch {
	$sidstr = $null
	}

Write-Host "Account: $($accountToAdd)" -ForegroundColor DarkCyan

if( [string]::IsNullOrEmpty($sidstr) ) {
	Write-Host "Account not found!" -ForegroundColor Red
	exit -1
}

Write-Host "Account SID: $($sidstr)" -ForegroundColor DarkCyan

$tmp = [System.IO.Path]::GetTempFileName()

Write-Host "Export current Local Security Policy" -ForegroundColor DarkCyan
secedit.exe /export /cfg "$($tmp)" 

$c = Get-Content -Path $tmp 

$currentSetting = ""

foreach($s in $c) {
	if( $s -like "SeBatchLogonRight*") {
		$x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
		$currentSetting = $x[1].Trim()
	}
}

if( $currentSetting -notlike "*$($sidstr)*" ) {
	Write-Host "Modify Setting ""Logon as a Batch Job""" -ForegroundColor DarkCyan

	if( [string]::IsNullOrEmpty($currentSetting) ) {
		$currentSetting = "*$($sidstr)"
	} else {
		$currentSetting = "*$($sidstr),$($currentSetting)"
	}

	Write-Host "$currentSetting"
	
$outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeBatchLogonRight = $($currentSetting)
"@

$tmp2 = [System.IO.Path]::GetTempFileName()

Write-Host "Import new settings to Local Security Policy" -ForegroundColor DarkCyan
$outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force

#notepad.exe $tmp2
Push-Location (Split-Path $tmp2)

	try {
		secedit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS 
		#write-host "secedit.exe /configure /db ""secedit.sdb"" /cfg ""$($tmp2)"" /areas USER_RIGHTS "
	} finally {	
		Pop-Location
	}
	} else {
	Write-Host "NO ACTIONS REQUIRED! Account already in ""Logon as a Batch Job""" -ForegroundColor DarkCyan
}

Write-Host "Done." -ForegroundColor DarkCyan

# ----------------------------------------------------------------------------------------------
# Script Ends
# ----------------------------------------------------------------------------------------------
