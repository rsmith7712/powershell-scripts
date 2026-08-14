# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Richard Smith

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
    Get-BackOfficeInstallStatus.ps1

.SYNOPSIS
    Get-BoInstallStatus.ps1

.DESCRIPTION
    Get-BoInstallStatus.ps1 pulls the installation status of the Fujitsu BackOffice Base and Service Pack software and returns it
    to SCCM or other recipient.
    
.EXAMPLE
    Get-BoInstallStatus.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  03/02/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Get-BoInstallStatus.ps1 pulls the installation status of the Fujitsu BackOffice Base and Service Pack software and returns it
        to SCCM or other recipient.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################

$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Get-BackOfficeInstallStatus"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:xmlFolder = "$script:script_dir"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
###########################################[FUNCTIONS ]############################################
Function Set-RunAsAdministrator()
{
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Write-host "Script is running with Administrator privileges!"
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
}#=========================================[End Function]==========================================
Function Log_ToSplunk
{
    Param
    (
        [parameter(Mandatory=$true,Position=0)][String]$Message,
        [parameter(Mandatory=$false,Position=1)][String]$Type = "Log",
        [parameter(Mandatory=$false,Position=2)][String]$Status = "Informational",    
        [parameter(Mandatory=$false,Position=3)][int]$ID = $Null
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
            uid = $script:uid
        }
    }
    $body = $body | ConvertTo-Json
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}#=========================================[End Function]==========================================
Function Get-BoSpInstallStatus()
{
    $ErrorActionPreference = "Stop"
    Try 
    {
        $spSetupLog = Get-Content "c:\gstr\instlog\svrpossetup.log"
        $spStatus01 = "Product: Fujitsu GlobalSTORE DOMAIN Application POS -- Installation completed successfully"
        $spStatus02 = "Windows Installer installed the product. Product Name: Fujitsu GlobalSTORE DOMAIN Application POS. Product Version: 20.14.0. Product Language: 1033. Manufacturer: Fujitsu America, Inc.. Installation success or error status: 0."
        if($spSetupLog -match $spStatus01)
        {
            $boSpStatus0 = "[STATUS] : Fujitsu BackOffice Service Pack installation was successful.";$rc0 = 0
        }
            else
            {
                $boSpStatus0 = "[STATUS] : Fujitsu BackOffice Service Pack installation was NOT successful.";$rc0 = 1
            }
        if($spSetupLog -match $spStatus02)
        {
            $boSpStatus1 = "[STATUS] : Fujitsu BackOffice Service Pack installation script exited successfully. Please review the output from 'c:\gstr\instlog\svrpossetup.log' for additional information.";$rc1 = 0
        }
            else
            {
                $boSpStatus1 = "[STATUS] : Fujitsu BackOffice Service Pack installation script did NOT exit successfully. Please review the output from 'c:\gstr\instlog\svrpossetup.log' for additional information.";$rc1 = 1
            }
    }
        Catch 
        {
            $boSpStatus1  = "[STATUS] : Fujitsu BackOffice Service Pack installation was NOT successful. The following exception occurred: $($_.Exception.Message).";$rc1 = 4
        }
    $ErrorActionPreference = "SilentlyContinue"        
        $exitcodevalue = $rc0 + $rc1
        Write-Output $boSpStatus0,$boSpStatus1,$exitcodevalue
}#=========================================[End Function]==========================================
Function Get-BoBaseInstallStatus()
{
    $ErrorActionPreference = "Stop"
    Try
    {
        $setupLog = Get-Content "c:\setup.txt"
        $setupExitMessage = "has exited with code 0"
        $setupCompleteMessage = "Installation complete"
        if($setupLog -match $setupExitMessage)
        {
            $boBaseStatus0 = "[STATUS] : Fujitsu BackOffice Base installation Exit Code 0.";$rc0 = 0
        }
            else
            {
                $boBaseStatus0 = "[STATUS] : Fujitsu BackOffice Base installation was NOT successful. Please review the output from c:\setup.txt for addition information.";$rc0 = 1
            }

        if($setupLog -match $setupCompleteMessage)
        {
            $boBaseStatus1 = "[STATUS] : Fujitsu BackOffice Base installation script exited successfully.";$rc1 = 0
        }
            else
            {
                $boBaseStatus1 = "[STATUS] : Fujitsu BackOffice Base installation script did NOT exit successfully.";$rc1 = 1
            }
    }
        Catch
        {
            $boBaseStatus0 = "[STATUS] : Fujitsu BackOffice Base installation was NOT successful. The following exception occurred: $($_.Exception.Message).";$rc1 = 4
        }
    $ErrorActionPreference = "SilentlyContinue"
        $exitcodevalue = $rc0 + $rc1
        Write-Output $boBaseStatus1,$boBaseStatus0,$exitcodevalue
}#=========================================[End Function]==========================================
###########################################[SCRIPT STARTS ]########################################
Log_ToSplunk -message "[STATUS] : $($env:COMPUTERNAME) : BackOffice base installation process has started."

$b = Get-BoBaseInstallStatus
$s = Get-BoSpInstallStatus
$boBaseExitCode = $b[2]
$boSpExitCode = $s[2]
$scriptExitCode = $b[2] + $s[2]
$boExitStatus = "[STATUS] : $($env:COMPUTERNAME) : BackOffice Base Installation Exit Code: $($boBaseExitCode)","[STATUS] : BackOffice Service Pack Installation Exit Code: $($boSpExitCode)","[STATUS] : Overall Installation Exit Code: $scriptExitCode"
$statusMsg = $b[0],$b[1],$s[0],$s[1]

Write-Output $statusMsg,$boExitStatus
Log_ToSplunk -message "[STATUS] : $($env:COMPUTERNAME) : BackOffice installation process has completed. For detailed status, please review the installation logs on the target device. Exit Code: $scriptExitCode"

Exit
###########################################[SCRIPT END ]###########################################
