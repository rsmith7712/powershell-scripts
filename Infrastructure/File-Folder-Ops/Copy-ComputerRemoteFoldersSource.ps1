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
    Copy-ComputerRemoteFoldersSource.ps1

.SYNOPSIS
Copy-RemoteSource.ps1

.DESCRIPTION
Copies remote folders locally to destination path specified.

.EXAMPLE
 Copy-RemoteSource.ps1

.NOTES
Version:        1.1
Author:         user10
Creation Date:  9/4/2019
Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Copies remote folders locally to destination path specified.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#################[Initializations]####################
[cmdletbinding()]
<#
param
(
    [ValidateSet('Store','ADQuery')]
    [string]$Target
)
#>
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$Script:ProductName = "Copy_RemoteSource.ps1"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).txt"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
#####################[Functions]######################
Function Set-RunAsAdministrator()
{
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Return-Output -message "Script is running with Administrator privileges!"
  }
  else
    {
        $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
        $ElevatedProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
        $ElevatedProcess.Verb = "runas"
        # $ElevatedProcess.WindowStyle = "MINIMIZE"
        [System.Diagnostics.Process]::Start($ElevatedProcess)
        Exit
    }
}#===================[End Function]===================
Function Return-Output($message,$color="white")
{
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Return-Output -message "$thetime`: $message" -ForegroundColor $color
}#===================[End Function]===================    
Function Get-Creds($u,$pw)
{
    # Set credentials for account executing script
    $p = ConvertTo-SecureString -AsPlainText -Force -String $pw
    $script:cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $u,$p
}#===================[End Function]===================
Function Test-RemoteSource($computer,$source)
{
    try
        {
            If(Test-Path "\\$($computer)\$($source)" -ErrorAction Stop)
            {
                $output = "SUCCESS: \\$($computer)\$($source) is accessible"
                $color = "White"
                $status = $true
            }
                else
                {
                    $output = "WARNING: The folder path \\$($computer)\$($source) was not found."
                    $color = "Yellow"
                    $status = $false
                }
        }
        catch
            {
                $output = "ERROR: The folder path: \\$($computer)\$($source) is not accessible from $($env:COMPUTERNAME). Exception Message: $($_.Exception.Message)"
                $color = "Red"
                $status = $false
            }
    Append-Log -message $output
    Return-Output -message $output -color $color
    return $status
}#===================[End Function]===================
Function Copy-RemoteSource($computer,$source,$destination,$script:cred,$robolog)
{
    try
        {
            Start-Process -Wait ROBOCOPY -WorkingDirectory "C:\Windows\System32" -argumentlist "\\$($computer)\$($source) $destination /MIR /XA:H /LOG:$robolog /FP /R:1 /W:1 /FFT /Z /NP" -Credential $script:cred
            $output = "Successfully started remote source copy process"
            $color = "White"
            $status = $true
        }
        catch
            {
                $output = "ERROR: ROBOCOPY \\$($computer)\$($source) failed. Exception Message: $($_.Exception.Message)."
                $color = "Red"
                $status = $false
            }
    Append-Log $output
    Return-Output -message $output -color $color
    return $status
}#===================[End Function]===================
Function Get-CopysourceStatus($computer,$source,$destination,$robolog)
{
    try
    {
    $sourcecount = (Get-ChildItem "\\$($computer)\$($source)" -Attributes !Directory+!Hidden -recurse | Measure-Object -property length).count
    $destcount = (Get-ChildItem $destination -Attributes !Directory+!Hidden -recurse | Measure-Object -property length).count
    $difference = $sourcecount - $destcount
        if($($difference) -ne 0)
        {
            $output = "WARNING: $($difference) files were not copied from $($computer)\$($source) to $($destination). Review the robocopy logs under '$($robolog)' for more details."
            $color = "Red"
            $status = $false
        }
            else
            {
                $output = "SUCCESS: All $($sourcecount) files were successfully copied from $($computer)\$($source) to $($destination)."
                $color = "Green"
                $status = $true
            }
    }
        catch
        {
            $output = "ERROR: Failed to obtain count of source or destination filesystem objects used to verify success or failure of remote source copy process.  Exception: $($_.Exception.Message)."
            $color = "Red"
            $status = $false
        }
    Append-Log $output
    Return-Output -message $output -color $color
    return $status
}
###################[Script Starts]####################
Set-RunAsAdministrator
$core = $env:COMPUTERNAME.substring(4,4)
if($core -eq "core")
{
Get-Creds -u "domain\orgsvc" -pw "<password>"
$store = Read-Host "Enter UFO_NUMBER"
#
$sources = @("c$\docs")
$computer = $store + "ST"
    ForEach($source in $sources){
        $TestSource = Test-RemoteSource -computer $computer -source $source
        if($TestSource -eq $true)
        {
            $robolog = "C:\temp\robocopy_log_$source.txt"
            $destination = "D:\sources\$source"
            $RemoteSourceCopy = Copy-Remotesource -computer $computer -source $source -destination $destination
            if($RemoteSourceCopy -eq $true)
            {
                Get-CopySourceStatus -computer $computer -source $source -destination $destination -robolog $robolog
            }
        }
            else
            {
                $output = "ERROR: $($computer)\$source is unavailable.  Ceasing remote copy process"
                Append-Log $output
                Return-Output -message $output -color "Red"
            }
    }
}
    else
    {
        $output = "This computer is not a CORE server.  Exiting script..."
        Append-Log $output
        Return-Output -message $output -color $color
        Start-Sleep -seconds 5
        Exit 1
    }
####################[Script End]######################

