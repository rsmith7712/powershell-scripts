# LEGAL
<# LICENSE
    MIT License, Copyright 1959 Richard Smith

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
    New-SCOAccount.ps1

.SYNOPSIS
    New-SCOAccount.ps1

.DESCRIPTION
    - New-SCOAccount.ps1 is for use when creating a new Domain retail Self-CheckOut (SCO) service accounts. A .csv file titled .\SCOAccounts.csv" is created
    with the corresponding samAccountName and pw for each account that was created. 

    - New accounts are created under "OU=Robot,OU=Service Accounts,OU=Domain Services,DC=DOMAIN,DC=com"
    
.EXAMPLE

    New-SCOAccount.ps1
    (New-SCOAccount.ps1 will prompt you to enter a UFO_NUMBER to process.)

    New-SCOAccount.ps1 -batch
    (New-SCOAccount.ps1 looks for a file called stores.txt in the same directory as the script and attempts to processes each UFO_NUMBER in the list.)

    New-SCOAccount.ps1 -stores 1959,1951,1955
    (New-SCOAccount.ps1 processes each UFO_NUMBER listed after the -stores parameter. UFO_NUMBERs must be comma separated.)
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  04/28/2021
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    - New-SCOAccount.ps1 is for use when creating a new Domain retail Self-CheckOut (SCO) service accounts. A .csv file titled .\SCOAccounts.csv" is created
        with the corresponding samAccountName and pw for each account that was created.

        - New accounts are created under "OU=Robot,OU=Service Accounts,OU=Domain Services,DC=DOMAIN,DC=com"

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
[cmdletbinding()]
param
(
    [switch]$batch,
    [array]$stores
)
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "New-DomainScoAccount.ps1"
$script:csvOutput = "$script:script_dir\SCOAccounts.csv"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "Continue"
###########################################[FUNCTIONS ]############################################
Function Set-RunAsAdministrator()
{
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Append_Log -message "Script is running with Administrator privileges!"
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
}#=======================================[ End Function ]==========================================
Function Append_Log
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$message,
        [parameter(Mandatory=$false,Position=1)][string]$color = "White"
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=======================================[ End Function ]==========================================
function Display-Error
{
    $title = "UFO_NUMBER Error"
    $message = "UFO_NUMBER must begin with 1,2,3,5,8, or 9, and contain exactly 4 integers. Try again?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Enter a 4 digit UFO_NUMBER"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Aborts and exits the script."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.ui.PromptForChoice($title, $message, $options, 1)
    return $result
}#=======================================[ End Function ]==========================================
Function Exit-Script() 
{
    Append_Log -message "Exiting Script..." -color "Yellow"
    Start-Sleep -Seconds 5
    Clear-Host
    Exit 1
}#=======================================[ End Function ]==========================================
Function Launch-MessageBox($msg,$title,$options)
{ #Prompt the user with a box and return their response
    Add-Type -AssemblyName System.Windows.Forms
    $message = [System.Windows.Forms.MessageBox]::Show($msg,$title,$options)
    return $message
}#=======================================[ End Function ]==========================================
Function Generate-Password($UFO_NUMBER)
{								
    $cubed = [Math]::Pow($UFO_NUMBER, 2)
    $hexnum = [Convert]::ToString($cubed, 16)
    $pwdObj = $hexnum.ToUpper()
    #$pw = convertto-securestring "$pwdObj" -asplaintext -force
    return $pwdObj
}#=======================================[ End Function ]==========================================
Function Load_PSModule($psModuleName)
{
    Try
    {
        $moduleversion = (Import-Module $psModuleName -PassThru -Force -ErrorAction "Stop").Version
        Append_Log -message "[STATUS] : PS module '$($psModuleName)' version: $moduleversion imported successfully."
    }
        Catch
        {
            Append_Log -message "[WARNING] : Failed to import PS module '$($psModuleName)'. The following exception occurred: $($_.Exception.Message)." -color "yellow"
            Start-Sleep -Seconds 5
            Exit-Script
        }
        $ErrorActionPreference = "SilentlyContinue"
}#=======================================[ End Function ]==========================================
Function New-ServiceAccount
{
    param
    (
        [Parameter(Mandatory=$true)][string]$samaccountname,
        [Parameter(Mandatory=$true)][string]$description,
        [Parameter(Mandatory=$true)][String]$password,
        [Parameter(Mandatory=$true)][string]$ou,
        [Parameter(Mandatory=$false)][string]$scoComputers
    )
    Try
    {
        $existing = Get-ADUser -Identity $samaccountname -ErrorAction Stop
        if(!($($existing.samaccountname) -match $samaccountname))
        {
            Append_Log "[STATUS] : $($samaccountname) already exists in AD. Unable to continue."
            Start-Sleep -Seconds 5
            Exit-Script
        }
    }
        Catch
        {
            Append_Log "[STATUS] : Confirmed $($samaccountname) does not exist in AD. Continuing with creation process."
        }
    if($($existing.samaccountname) -match $samaccountname)
    {
        Append_Log "$samaccountname already exists. Exiting..."
        return "$samaccountname already exists."
    }
    [string]$dateStamp = Get-Date -Format MM/dd/yyyy
    $pw = convertto-securestring "$password" -asplaintext -force
    $upn = $samaccountname + "@example.com"
    [string]$givenName = $samaccountname.substring(0,4)
    $description = "RBT Account [Created by $env:USERNAME on $($dateStamp)]"
    $ErrorActionPreference = "stop"
    Try
    {
        New-ADUser -Path $ou -Name "$samaccountname"  -AccountPassword $pw -Enabled $true -AllowReversiblePasswordEncryption $false -CannotChangePassword $true -PasswordNeverExpires $true -Surname "RBT" -GivenName $givenName -UserPrincipalName $upn -Description $description
        return "success"
    }
        Catch
        {
            Append_Log "[EXCEPTION] : The following exception occurred while attempting to create the new AD account: $($_.Exception.Message)."
            return "fail"
        }
    $ErrorActionPreference = "SilentlyContinue"
    Start-Sleep -Seconds 5
    $validate = Get-ADUser -Identity $samaccountname
    if($($validate.samaccountName) -match $samaccountname)
    {
        Append_Log "[STATUS] : Successfully created $($samaccountname)"
    }
        else
        {
            Append_Log "[ERROR] : The attempt to create 'DOMAIN\$($samaccountname)' was NOT successful."
        }
}#=======================================[ End Function ]==========================================
Function Get-UFO_NUMBER() 
{
    Clear-Host
    <#
    $question = "Please Enter the UFO_NUMBER associated with the new account:"
    $title = "UFO_NUMBER"
    [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
    $UFO_NUMBER = [Microsoft.VisualBasic.Interaction]::InputBox($question, $title)
    #>
    $UFO_NUMBER = Read-Host -Prompt "Please Enter the UFO_NUMBER for the New Account"
    if(!([regex]$($UFO_NUMBER) -match "^[1-3,5,8]\d\d\d$"))
    {
        $decision = Display-Error
        if($decision -eq 0)
        {
            Get-UFO_NUMBER
        }
            else
            {
                Append_Log -message "No UFO_NUMBER entered. Unable to continue." -color "Yellow"
                Exit-Script
            }
    }
        else
        {
            return $UFO_NUMBER
        }
}#=======================================[ End Function ]==========================================
Function Set-SCOAccount
{
   param
    (
        [Parameter(Mandatory=$true)][string]$samaccountname,
        [Parameter(Mandatory=$true)][string]$scoComputers
    )
    Try
    {
        $existing = Get-ADUser -Identity $samaccountname -ErrorAction Stop
        if(!($($existing.samaccountname) -match $samaccountname))
        {
            Append_Log "$samaccountname does NOT exist. Unable to continue."
            return "$samaccountname does NOT exist. Unable to continue."
        }
    }
        Catch
        {
            Append_Log "[STATUS] : Verfied $($samaccountname) exists. Populating the 'userWorkstations' list attribute in AD."
        }
        $ErrorActionPreference = "Continue"
    Try
    {
        Set-ADUser -Identity $samaccountname -LogonWorkstations $($scoComputers) -replace @{userAccountControl=66080} -ErrorAction Stop
        [string]$userworkstations = (Get-ADUser -Identity $samaccountname -Properties userWorkstations).userWorkstations
        if($($userworkstations) -match $($scoComputers))
        {
            Append_Log "[STATUS] : Successfully added $($scoComputers) to the 'userWorkstations' list attribute in AD for $($samaccountname)."
        }
            else
            {
                Append_Log "[ERROR] : FAILED to add $($scoComputers) to the 'userWorkstations' list attribute in AD for $($samaccountname)."
            }
    }
        Catch
        {
            Append_Log "[EXCEPTION] : The following exception occurred while attempting to modify the userWorkstations AD Attribute: $($_.Exception.Message)."
        }
        $ErrorActionPreference = "Continue"
}#=======================================[ End Function ]==========================================
Function Get-SCOComputers($UFO_NUMBER)
{
    $ErrorActionPreference = "Stop"
    Try
    {
        $ScoHosts = @()
        (Get-ADComputer -Filter "name -like '$($UFO_NUMBER)SCO*'").Name |
        ForEach-Object{
            $scoHosts += $_
        }
    }
        Catch
        {
            Append_Log "[STATUS] : No existing SCO hosts were located in AD for $UFO_NUMBER."
        }
        Finally
        {
            if(!(($null -like $ScoHosts) -or ($ScoHosts -like "")))
            {
                Append_Log "[STATUS] : Located the following SCO computers for store $($UFO_NUMBER):`n$ScoHosts"
            }
        }

        $ErrorActionPreference = "Continue"
        [string]$scoComputers = $ScoHosts
        $scoComputers = $scoComputers.Replace(" ",",")

    if(($null -like $ScoHosts) -or ($ScoHosts -like ""))
    {
        Write-Host "Generating SCO Hostname." -ForegroundColor Yellow
        $ErrorActionPreference = "Stop"
        Try
        {
            $regArray = @()
            (Get-ADComputer -filter "samAccountName -like '*$($UFO_NUMBER)REG*'" -SearchBase "DC=DOMAIN,DC=com").Name |
            ForEach-Object{
                $regName = $_
                [int]$regSuffix = ($regName -Split "g")[1]
                $regArray += $regSuffix
            }
            $var = ($regArray | Sort-Object)[-1] + 1
            [string]$suffix = $var
            [string]$suffix1 = $var + 1
            [string]$suffix2 = $var + 2
            [string]$suffix3 = $var + 3
            [string]$suffix4 = $var + 4
            [string]$scoComputers = "$([string]$UFO_NUMBER)SCO$($suffix),$([string]$UFO_NUMBER)SCO$($suffix1),$([string]$UFO_NUMBER)SCO$($suffix2),$([string]$UFO_NUMBER)SCO$($suffix3),$([string]$UFO_NUMBER)SCO$($suffix4)"
        }
            Catch
            {
                Append_Log "[EXCEPTION] : The following exception occurred: $($_.Exception.Message)."
            }
            $ErrorActionPreference = "Continue"
    }
    return $scoComputers
}#=======================================[ End Function ]==========================================
###########################################[SCRIPT STARTS]########################################
Clear-Host
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
Set-RunAsAdministrator
Append_Log -message "[BEGIN]"
#--------------------------------------------------------------------------------------------------
$newAccountCount = 0
$newAccountFailCount = 0
$totalCount = 0
if($batch -eq $true)
{
    if(Test-Path "$script:script_dir\stores.txt")
    {
        $stores = Get-Content "$script:script_dir\stores.txt"
    }
        else
        {
            Clear-Host
            Append_Log "Unable to locate '$script:script_dir\stores.txt'. Please ensure this file exists and `ncontains a list of UFO_NUMBERs to process." -color "Yellow"
        }
}
Load_PSModule -psModuleName "ActiveDirectory"
foreach($store in $stores)
{
    if(!([regex]$($store) -match "^[1-3,5,8]\d\d\d$"))
    {
        $decision = Display-Error
        if($decision -eq 0)
        {
           [string]$UFO_NUMBER = Get-UFO_NUMBER
        }
            else
            {
                Append_Log "No UFO_NUMBER entered. Unable to continue."
                Exit-Script
            }
    }
        else
        {
            [string]$UFO_NUMBER = $store
        }

    $ou = "OU=Robot,OU=Service Accounts,OU=Domain Services,DC=DOMAIN,DC=com"
    $samAccountName = $UFO_NUMBER + "RBT"
    [string]$pw = Generate-Password -UFO_NUMBER $UFO_NUMBER
    [string]$ScoHosts = Get-SCOComputers -UFO_NUMBER $UFO_NUMBER
    [string]$exitStatus = New-ServiceAccount -samaccountname $samAccountName -description "SCO Account for Store $($UFO_NUMBER)" -ou $ou -password $pw
    $totalCount++
    if($exitStatus -match "success"){$newAccountCount++}
    Set-SCOAccount -samaccountname $samAccountName -scoComputers $ScoHosts.Trim()    
    $output = @()
    $csv = $script:csvOutput    
    $newObj = New-Object PSObject -Property ([Ordered]@{
        samAccountName = [string]$samAccountName
        password = [string]$pw
        status = [string]$exitStatus
        userWorkstations = [string]$ScoHosts
    })
    $newObj
    $output += $newObj    
}
    $output | Export-Csv -Path $($csv) -NoTypeInformation -Append
#--------------------------------------------------------------------------------------------------
Append_Log -message "[COMPLETION] : Count of New Accounts Created: $($newAccountCount)."
$elapsed = [math]::Round($stopwatch.Elapsed.TotalMinutes,2)
$stopwatch.Stop()
$successRate = $newAccountCount/$totalCount
Append_Log -message "[COMPLETION] : Time Elapsed: $($elapsed).`nCreated: $($newAccountCount) `nAttempts: $($totalCount) `nSuccess Rate: $($successRate.ToString("P"))"
Exit
###########################################[SCRIPT ENDS]##########################################