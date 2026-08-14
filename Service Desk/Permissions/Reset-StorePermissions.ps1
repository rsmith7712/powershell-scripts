# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Reset-StorePermissions.ps1

.SYNOPSIS
  Fixes share and folder permissions on a target store computer
   
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  06/21/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Fixes share and folder permissions on a target store computer

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "Reset-StorePermissions" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.

# Functions
#################################
function Log_ToSplunk
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $Message,

        [parameter(Mandatory=$false,
        Position=1)]
        $Type = "Log",

        [parameter(Mandatory=$false,
        Position=2)]
        $Status = "Informational",

        [parameter(Mandatory=$false,
        Position=3)]
        $ID = $Null
    )

    $product = "team_" + $Script:ProductName
    $uri = "https://hecext.example.com:18443/services/collector/event"
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.add('Authorization', 'Splunk Application-Key-Here')
    $body = @{
        sourcetype = 'domain:ps:log'
        host = $env:COMPUTERNAME
        event = @{
            message = $Message
            user = $env:USERNAME
            product = $Product
            type = $Type
            status = $Status
            id = $ID
        }
    }
    $body = $body | ConvertTo-Json
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}

function set-homepath
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $computer
    )
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

    $store = $computer.substring(0,4)
    $str = $store + "str"
    $mgr = $store + "mgr"
    
    $parentpath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\'
    $items = Get-ChildItem $parentpath | Get-ItemProperty | Select-Object -Property pschildname
    $SIDs = @()
    foreach($item in $items)
    {
        $SIDs += $item.pschildname
    }
    
    $strmatch = 0
    $mgrmatch = 0
    foreach($SID in $SIDs)
    {
        $path = $parentpath + $SID
        if((Get-ItemProperty -Path $path -Name profileimagepath).profileimagepath.substring(9,7).trim() -eq $str)
        {
            $strmatch++
            $shellpath = "HKU:\$($SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
            Set-ItemProperty -Path $shellpath -Name "Personal" -Value "\\$($store)ST\Docs" -Force
            Set-ItemProperty -Path $shellpath -Name "My Pictures" -Value "\\$($store)ST\Docs\StorePictures" -Force
            $usershellpath = "HKU:\$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
            Set-ItemProperty -Path $usershellpath -Name "Personal" -Value "\\$($store)ST\Docs" -Force
            Set-ItemProperty -Path $usershellpath -Name "My Pictures" -Value "\\$($store)ST\Docs\StorePictures" -Force
        }
        elseif((Get-ItemProperty -Path $path -Name profileimagepath).profileimagepath.substring(9,7).trim() -eq $mgr)
        {
            $mgrmatch++
            $shellpath = "HKU:\$($SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
            Set-ItemProperty -Path $shellpath -Name "Personal" -Value "\\$($store)ST\Docs" -Force
            Set-ItemProperty -Path $shellpath -Name "My Pictures" -Value "\\$($store)ST\Docs\StorePictures" -Force
            $usershellpath = "HKU:\$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
            Set-ItemProperty -Path $usershellpath -Name "Personal" -Value "\\$($store)ST\Docs" -Force
            Set-ItemProperty -Path $usershellpath -Name "My Pictures" -Value "\\$($store)ST\Docs\StorePictures" -Force
        }
    }
    Remove-PSDrive -Name HKU -Force
    $output = New-Object -TypeName psobject -Property @{
        StoreMatch = $strmatch
        ManagerMatch = $mgrmatch
    }
    return $output
}    

function set-mappeddrive
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $computer
    )
    $st = $computer.substring(0,4) + "ST"
    NET USE r: /delete
    Start-Sleep -Seconds 5
    NET USE r: "\\$st\Reports" /persistent:yes
    
    if(Get-PSDrive -PSProvider FileSystem | Where-Object {$_.root -eq "R:\"})
    {
        return $true
    }
    else 
    {
        return $false
    }
}

# Variables
#################################

$stcheck = $false
do
{
    $computer = Read-Host "Enter Computer Name"
    if(($computer.substring(4,2) -eq "st") -or ($computer.Substring(4,2) -eq "js") -or ($computer.Substring(4,2) -eq "s2") -or ($computer.Substring(4,2) -eq "s3"))
    {
        $stcheck = $true
    }
    else 
    {
        Write-Host "Not a store computer, try again."
    }
}
while($stcheck -eq $false)

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

$action = Invoke-Command -ComputerName $computer -ScriptBlock ${function:set-homepath} -ArgumentList $computer
if($action.StoreMatch -gt 0)
{
    Write-Host "STR account permissions updated on $computer"
    Log_ToSplunk -Message "STR account permissions updated on $computer" -Status "success"
}
if($action.ManagerMatch -gt 0)
{
    Write-Host "MGR account permissions updated on $computer"
    Log_ToSplunk -Message "MGR account permissions updated on $computer" -Status "success"
}
$action2 = Invoke-Command -ComputerName $computer -ScriptBlock ${function:set-mappeddrive} -ArgumentList $computer
if($action2 = $true)
{
    write-host "R:\ drive mapped succesfully"
    Log_ToSplunk -Message "R:\ drive mapped succesfully on $computer" -Status "success"
}
elseif($action2 = $false)
{
    Write-Host "R:\ drive could not be mapped"
    Log_ToSplunk -Message "R:\ drive could not be mapped on $computer" -Status "fail"
}

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit