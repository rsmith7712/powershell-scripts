# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Get-FSMORole.ps1

.DESCRIPTION
    		A description of the file.

.FUNCTIONALITY
    		A description of the file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function Get-FSMORole
{
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $True)]
		[string[]]$DomainName = $env:USERDOMAIN
	)
	BEGIN
	{
		Import-Module ActiveDirectory -Cmdlet Get-ADDomain, Get-ADForest -ErrorAction SilentlyContinue
	}
	PROCESS
	{
		foreach ($domain in $DomainName)
		{
			Write-Verbose "Querying $domain"
			Try
			{
				$problem = $false
				$addomain = Get-ADDomain -Identity $domain -ErrorAction Stop
			}
			Catch
			{
				$problem = $true
				Write-Warning $_.Exception.Message
			}
			if (-not $problem)
			{
				$adforest = Get-ADForest -Identity (($addomain).forest)
				New-Object PSObject -Property @{
					InfrastructureMaster = $addomain.InfrastructureMaster
					PDCEmulator = $addomain.PDCEmulator
					RIDMaster = $addomain.RIDMaster
					DomainNamingMaster = $adforest.DomainNamingMaster
					SchemaMaster = $adforest.SchemaMaster
				}
			}
		}
	}
}
Get-FSMORole