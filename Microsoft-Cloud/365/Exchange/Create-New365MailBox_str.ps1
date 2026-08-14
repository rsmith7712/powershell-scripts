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
    Create-New365MailBox_str.ps1

.SYNOPSIS
    Migrate-ExchangeMailBoxes.ps1

.DESCRIPTION
    Migrate-ExchangeMailBoxes.ps1
    
.EXAMPLE
    Migrate-ExchangeMailBoxes.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  7/15/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Migrate-ExchangeMailBoxes.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
<#
[cmdletbinding()]
param
(
    [string]$param1
    [string]$<ParamName> = $(throw "[ERROR] : -<ParamName> parameter is required.")
    [ValidateSet('item1','item2')]    
)
#>
$script:ScriptName = "Migrate-ExchangeMailBoxes"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Deploy-WastedAuditTask_d"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
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
Function Process-Output
{
    param
    (
        [parameter(Mandatory=$true)][string]$message,
        [parameter(Mandatory=$false)][string]$splunkLog = $false,
        [parameter(Mandatory=$false)][string]$splunkType,
        [parameter(Mandatory=$false)][string]$splunkStatus,
        [parameter(Mandatory=$false)][string]$color = "white"
    )
    If($splunkLog)
    {
        Log_ToSplunk -Message $message -Type $splunkType -Status $splunkStatus
    }
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=========================================[END Function]==========================================
Function Import-ExchangePSModule()
{
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;   
    Return $?
}#===============================[ End Function ]==========================
Function Disable-OnPremMailbox($aliasSTR)
{
 #disable on-prem mailbox
    Disable-Mailbox  -Identity "$aliasSTR" -Confirm:$false
    Return $?
}#===============================[ End Function ]==========================

Function Create-O365Mailbox($aliasSTR)
{
    $aliasRemoteSTR = $aliasSTR + "STR" 
    #Create new o365 mailbox
    Enable-RemoteMailbox -Identity $aliasRemoteSTR -Alias $aliasSTR -RemoteRoutingAddress ($aliasSTR + "@domain.mail.onmicrosoft.com")
    Return $?
}#===============================[ End Function ]==========================
Function Add-o365Aliass($aliasSTR) 
{
    #add alias email addresses
    Set-RemoteMailbox [string]$aliasSTR -EmailAddresses @{add='[string]$($aliasSTR)@example.com'}
    Return $?
}#===============================[ End Function ]==========================
Function Get-O365Mailbox($aliasSTR)
{
    Try
    {
        Get-Mailbox -Identity $($aliasSTR) -ErrorAction Stop
    }
        Catch
        {
            $e = $($_.Exception.Message)
            Write-Host "[EXCEPTION] : $e`n`n" -ForegroundColor White -BackgroundColor Magenta
        }
        $ErrorActionPreference = "SilentlyContinue"
    Return $?
}#===============================[ End Function ]==========================

################################[ SCRIPT STARTS ]##########################

# [Un-Comment to excecute this function] 

Import-ExchangePSModule

$csvImportFile = "\\SERVER\SHARE\...\MailboxRecoverySTR.csv"

    $csvImportFile | Import-Csv | Where-Object{!([regex]$($_.Alias) -match "MGR")} | 
    ForEach-Object{
        [string]$aliasSTR = $($_.Alias)
        Write-Host "[STATUS] : Start Processing Mailbox for $($aliasSTR)" -ForegroundColor White -BackgroundColor Blue
        Try
        {
            $mbObj = ""
            $mbObj = Get-Mailbox -Identity $aliasSTR  -ErrorAction Stop
            $output = "This is the alias from AD/Exchange: $($mbObj.Alias)"
            Write-Host $output -ForegroundColor Yellow -BackgroundColor Black
        }
            Catch
            {
                $e = $($_.Exception.Message)
                $output = "[ERROR] : The following exception occurred when attempting to process the On-Premesis mailbox: $($aliasSTR). [EXCEPTION] : $e`n`n"
                Write-Host $output -ForegroundColor White -BackgroundColor Red
            }
            $ErrorActionPreference = "SilentlyContinue"

        # [Un-Comment to excecute this function] 
        $oldmbdisabled = Disable-OnPremMailbox -aliasSTR $aliasSTR
        Write-Host "[STATUS] : Old Mailbox disabled status for $aliasSTR : $oldmbdisabled" -ForegroundColor Yellow

        # [Un-Comment to excecute this function] 
        $newmbCreated = Create-O365Mailbox -aliasSTR $aliasSTR
        Write-Host "[STATUS] : New Mailbox creation status for $aliasSTR : $($newmbCreated)" -ForegroundColor Magenta
Try 
{
    Get-RemoteMailbox -Identity $aliasSTR -ErrorAction Stop
}
    Catch
    {
        $e = $($_.Exception.Message)
        $output = "[ERROR] : The following exception occurred when attempting to process the REMOTE mailbox: $($aliasSTR). [EXCEPTION] : $e`n`n"
        Write-Host $output -ForegroundColor White -BackgroundColor Black
    }
$ErrorActionPreference = "SilentlyContinue"



        # [Not used for original mailbox migration] # [Un-Comment to excecute this function] Add-o365Aliass -$aliasSTR $aliasSTR
    }
################################[ SCRIPT ENDS ]################################