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
    Delete-WastedFiles.ps1

.DESCRIPTION
    Deletes 'wasted' files across a target with administrative elevation and a logging framework (part of the storage-cleanup tooling).

.FUNCTIONALITY
    Deletes wasted files with logging.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$script:ScriptName = "Delete-WastedFiles.ps1"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Delete-WastedFiles"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
Function Set-RunAsAdministrator()
{
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Write-Output "Script is running with Administrator privileges!"
  }
  else
    {
        $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
        $ElevatedProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
        $ElevatedProcess.Verb = "runas"
        $ElevatedProcess.WindowStyle = "MINIMIZE"
       [System.Diagnostics.Process]::Start($ElevatedProcess)
       Exit
    }
}#=========================================[END Function]==========================================
Function Process-Output
{
    param
    (
        [parameter(Mandatory=$true)][string]$message
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Output "$thetime`: $message"
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=========================================[END Function]==========================================
Process-Output "[START] : Script Begins."
$computer = $env:COMPUTERNAME
$outfile = "C:\temp\wastedTotals.csv"
if(Test-Path $outfile){Remove-Item $outfile -Force}
$letters = @("c","d","e","f","g","h","I","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")
foreach($vol in $letters){
    if(Test-Path "$vol`:\")
    {
        $wastedcount = 0
        $deletedcount = 0
        $drive = "$vol`:"
        $drive
        Set-Location '\'
        Process-Output -message "[STATUS] : Volume: $drive\ discovered on $computer"
            Get-ChildItem -Path "$drive\" -Recurse -Force | Where-Object {[regex]$($_.Extension) -match "domainwasted"} |
            ForEach-Object {
                $wastedcount++
                $ErrorActionPreference = "Stop"
                Try
                {
                    $parentPath = $_.DirectoryName
                    $filepath = $_.FullName
                    Write-Output "Attempting to Delete: $filepath"
                    cmd /c del /q $filepath /f
                    Remove-Item -Path $filepath -Force -Recurse
                    $deletedcount++
                }
                    Catch
                    {
                        Process-Output "[ERROR] : The following exception occurred: $($_.Exception.Message). Full Path: $filepath"
                        takeown /F $parentPath\* /R /A
                        icacls $parentPath\*.* /T /grant administrators:F
                        #cmd /c del /q $filepath /f
                    }

                Finally
                {
                    $ErrorActionPreference = "SilentlyContinue"
                }
            }

            [string]$totalwasted = $wastedcount
            [string]$totaldeleted = $deletedcount
            [string]$totalRemaining = ($totalwasted - $totaldeleted)
            [string]$computer = $env:COMPUTERNAME
        Process-Output "[STATUS] : Computer $computer | Volume $vol`: Total found - $totalwasted Total deleted - $totaldeleted Total remaining - $totalRemaining"
        "$computer,$vol,$totalwasted,$totaldeleted,$totalRemaining" | Out-File $outfile -Append ascii
    }            
}
Process-Output "[END] : Script completion. Exiting."
Exit
