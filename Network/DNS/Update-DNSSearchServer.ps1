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
    Update-DNSSearchServer.ps1

.SYNOPSIS
  Bulk Update the DNS static IP to the latest search server on the production devices via CSV import file with HostName header.  
  This is a wrapper for the Set-DNSConf.ps1 to loop through foreach of a list of machine names to update to. 
 
.DESCRIPTION
  Does Stuf.
  
.NOTES
  Version:        1.0 
  Modified by:	  
  Creation Date:  05/13/2019
  Purpose/Change: Initial Script Development 

.HISTORY
  Version:        1.0 
  Author:         Tony Chu
  Modified by:	  
  Creation Date:  05/13/2019
  Purpose/Change: Initial Script Development
  Version:        1.0

.FUNCTIONALITY
    Does Stuf.

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
$Script:ProductName = "UpdateDNSSearchServer"

$ChangeDate = (Get-Date).AddDays(+1).ToString('MM/dd/yyyy')
$CsvFile = "C:\temp\DNSTest.csv"
$SCRIPT = "C:\temp\Set-DNSConfig.ps1"
$GrantRight = "C:\temp\GrantLogonBatchJobPermission.ps1"
$REMOTE_FILE = $SCRIPT -replace ":","$"
$REMOTE_FILE_GrantRight = $GrantRight -replace ":","$"

$logDir = "C:\Logs"
$script:LogFile = "C:\temp\UpdateDNSSearchServer.log"
$PrevLog = "C:\temp\UpdateDNSSearchServerPrev.log"

# Local Logging
#################################
If(!(Test-Path $LogDir))
{
    New-Item -Path $LogDir -ItemType Directory
}
If(Test-Path $script:LogFile)
{
    Remove-Item $PrevLog -Force
    Rename-Item $script:LogFile -NewName "UpdateDNSSearchServerPrev.log" -Force
}
New-Item $script:LogFile -type file -force
function Write-Log($message)
{
    $dateTime = Get-Date -Format g
	Add-Content $script:LogFile "`n$dateTime : $message"
}

# Functions
#################################
function Log_ToSplunk{
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
    [int]
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
   
# ----------------------------------------------------------------------------------------------
# Script Starts
# ----------------------------------------------------------------------------------------------
# Loop through the file list containing the static DNS IP to update to the latest 
# Import the CSV file. 
Try {$SERVERS = Import-Csv $CsvFile} 
Catch 
{ 
    Write-Host "Invalid CSV file $CsvFile!!" ` 
        -ForegroundColor Red -BackgroundColor Black 
    Write-Host "Script Aborted." -ForegroundColor Red -BackgroundColor Black 
    Break 
}

Foreach ($SERVER in $SERVERS)
{
    $SERVER = $SERVER.HostName.Trim() 

	If((Test-Connection -ComputerName $SERVER -Quiet) -eq $True)
	{
        Write-Log "$SERVER is online."

        # Copy file to the remote machine
        Try
        {
            Copy-Item -Path "$SCRIPT" -Destination "\\$SERVER\$REMOTE_FILE" -Force
            Copy-Item -Path "$GrantRight" -Destination "\\$SERVER\$REMOTE_FILE_GrantRight" -Force 
            Write-Log "Copied $SCRIPT to $SERVER"

            # Execute the powershell remotely 
            Invoke-Command -ComputerName $SERVER -FilePath "\\$SERVER\c`$\...\GrantLogonBatchJobPermission.ps1" 


            #Creates the new scheduled Task 
            &SCHTASKS /create /s $SERVER /TN "DNSSearchServerUpdate" /SC "Once" /RU "domain\orgsvc" /RP "<password>" /ST "21:00" /SD $ChangeDate /TR "Powershell.exe -executionpolicy bypass -file C:\temp\Set-DNSConfig.ps1" /f 

            # Execute the powershell remotely 
            Invoke-Command -ComputerName $SERVER -FilePath "\\$SERVER\$REMOTE_FILE"

            # Log to local file 
            Write-Log "Successfully Updated $SERVER to the latest DNS"
        }
        Catch{
            Write-Log "Failed to copy $SCRIPT to $SERVER"
        }
    }
    Else{
        Write-Log "$SERVER is offline."

        # Log to local file 
        Write-Log "Failed to update the $SERVER to the latest DNS"
    }
}

# ----------------------------------------------------------------------------------------------
# Script Ends
# ----------------------------------------------------------------------------------------------
