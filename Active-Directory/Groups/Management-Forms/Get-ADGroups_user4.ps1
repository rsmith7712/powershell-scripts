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
    Get-ADGroups_user4.ps1

.DESCRIPTION
    Exports the membership of every Active Directory group to CSV (reference/commented snippet).

.FUNCTIONALITY
    Exports AD group memberships (reference).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
$groupmembership = get-adgroup -filter * |
    ForEach-Object{
        Write-Host $_.DistinguishedName -fore green
        $props = @{Group=$_.DistinguishedName;Member=$null}
        $_ | get-adgroupmember |
          ForEach-Object{
                    Write-Host "`t$($_.DistinguishedName)" -fore yellow
                    $props.Member=$_.DistinguishedName
                    New-Object PsObject -Property $props
                }
    }
$groupmembership | Out-File C:\AD_GroupMembership_Details.csv
#>

$ErrorActionPreference = "SilentlyContinue"

# ----------------------------------------------------------------------------------------------
# Logging
$script:log_full_filepath = "C:\temp\report-AD_GroupMembership_Details.csv"
If(Test-Path $script:log_full_filepath){
    Remove-Item $script:log_full_filepath -Force
	}
New-Item $script:log_full_filepath -type file -force
function append_log($message){
	Add-Content $script:log_full_filepath "$message"
    }

Add-Content $script:log_full_filepath "Group,User"

Function Dump-Members($Group)
{
    #Append_log "`n"
    $Current = $Group.Name
    #$Users = ($Group.Members | Get-ADuser).name
    $Users = ($Group.Members | Get-ADobject).name
    $Count = $Users.Count
    If($Count -eq 0){
        Append_log "$Current,"
    }

    ForEach($User in $Users)
    {
        #Append_log "$Current,$User"
        If($Count -eq 1){
            Append_log "$Current,$User"
        }
        ElseIf($User -eq $Users[0])
        {
            Append_log "$Current,$User"
        }
        else {
            Append_log ",$User"
        }
    }
}

$GroupMembership = Get-AdGroup -ResultSetSize 5000 -Filter * -Properties Name,Members

ForEach ($Group in $groupmembership)
{
    Dump-Members $Group
}
