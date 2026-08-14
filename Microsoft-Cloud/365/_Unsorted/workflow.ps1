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
    workflow.ps1

.SYNOPSIS
  Bulk create folders with permission list via CSV import file with header names as [name] and [EmailAddress] from C:\temp\SharePointFolderNameList.csv   
  Example from the csv file content
      name,EmailAddress
      NewFolder1,user9admin@example.com 
 
.DESCRIPTION
  This script contains the following 3 functions: 
      Connect-SharePoint # Used to connect to the SharePoint site
      Create-FolderAndAddPermission # Used to create multiple folders with permission via CSV data feed
      Create-SingleFolderAndAddPermission $folderName $useralias # Used to create single folder 
  
.NOTES
  Version:        1.0 
  Modified by:	  
  Creation Date:  06/19/2019
  Purpose/Change: Initial Script Development 

.HISTORY
  Version:        1.0 
  Author:         Tony Chu
  Modified by:	  
  Creation Date:  06/19/2019
  Purpose/Change: Initial Script Development
  Version:        1.0

.FUNCTIONALITY
    This script contains the following 3 functions:
          Connect-SharePoint # Used to connect to the SharePoint site
          Create-FolderAndAddPermission # Used to create multiple folders with permission via CSV data feed
          Create-SingleFolderAndAddPermission $folderName $useralias # Used to create single folder

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Check Script is running with Elevated Privileges
Function Check-RunAsAdministrator()
{
  #Get current user context
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())

  #Check user is running the script is member of Administrator Group
  if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Write-host "Script is running with Administrator privileges!"
  }
  else
    {
       #Create a new Elevated process to Start PowerShell
       $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
       
       #Specify the current script path and name as a parameter
       $ElevatedProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
       
       #Set the Process to elevated
       $ElevatedProcess.Verb = "runas"

       #Start the new elevated process
       [System.Diagnostics.Process]::Start($ElevatedProcess)

       #Exit from the current, unelevated, process
       Exit
    }
}	

Check-RunAsAdministrator
#Read more: http://www.sharepointdiary.com/2015/01/run-powershell-script-as-administrator-automatically.html

# Initializations
$script:scriptFilepath = $MyInvocation.MyCommand.Path
$script:scriptDir = Split-Path -Parent $script:scriptFilepath
$errorActionPreference = "SilentlyContinue"
$Script:ProductName = "Create-SharePointFolder"
$Script:UID = [guid]::NewGuid()  
$ChangeDate = (Get-Date).AddDays(+1).ToString('MM/dd/yyyy')
$CsvFile = "C:\temp\SharePointStoresFolderNameList.csv"
$storeslist = "C:\Temp\storeslist.csv"
$username = "flowautomation@example.com"
$password = "<password>"
$ListName = "Shared Documents"
$WebAppURL = "https://domain.sharepoint.com/sites/Automation-Test-Site"
$access = "Read" # "Full Control"
$datetime = (Get-Date).ToString('yyyyMMddHHmmss')
$folderName = "NewFolder$datetime"
$useralias = "user2@example.com"
$LogDir = "C:\Logs"
$script:LogFile = "C:\temp\CreateSharePointFolders.log"

$source = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution\"
$sourcePDF = "\\SERVER\SHARE\...\REPORTS"
$previousYear = (Get-Date -Format yyyy) - 1 
$currentYear = Get-Date -Format yyyy
$sourcePreviousYear = $source + $previousYear 
$sourceCurrentYear = $source + $currentYear

# Install required SharePoint PnP Module 
Install-Module SharePointPnPPowerShellOnline

# Local Logging
#################################
If(!(Test-Path $LogDir))
{
    New-Item -Path "c:\" -Name "Logs" -ItemType "directory"
}

If(!Test-Path $script:LogFile)
{
    New-Item $script:LogFile -type file -force
}

Function Write-Log($message)
{
    $dateTime = Get-Date -Format g
	Add-Content $script:LogFile "`n$dateTime : $message"
}

# Functions
#################################
Function Log_ToSplunk{
    Param(
    [parameter(Mandatory=$true,
    Position=0)]
    [String]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    [String]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    [String]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
    [String]
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

Function Connect-SharePoint{
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
    Connect-PnPOnline -Url $WebAppURL -Credentials $cred
}
workflow test-workflow {
    $source = "\\SERVER\SHARE\...\" # Dropbox source location 
    $currentYear = Get-Date -Format yyyy
    $sourceCurrentYear = $source + $currentYear
    
    $sourcePath = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution"
    $computers = Split-Path -Path "$sourcePath\$currentYear\P1\Wk 1\Critical\*.xlsx" -Leaf -Resolve

    ForEach -parallel ($computer in $computers){
        InlineScript{
        function func1{
            Write-Output "Func 1"
            logMessage
        }

        function logMessage{
            Write-Output "logMessage"
        }
        func1
        }

        $folderName = $computer.Substring(0,4)
        $folderName
            
    }  
}
test-workflow