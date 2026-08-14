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
    Remove-McAfee.ps1

.SYNOPSIS
  Bulk uninstall the McAfee from the corporate devices via CSV import file with HostName header from C:\temp\McAfeeHostNameList.csv  
  This script copy the PowerShell file each of the hostname as well as to create the task scheduler to call it once 1 day from the execution day. 
 
.DESCRIPTION
  Does Stuf.
  
.NOTES
  Version:        1.0 
  Modified by:	  
  Creation Date:  05/31/2019
  Purpose/Change: Initial Script Development 

.HISTORY
  Version:        1.0 
  Author:         Tony Chu
  Modified by:	  
  Creation Date:  05/31/2019
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
$Script:ProductName = "Remove-McAfee"
$Script:UID = [guid]::NewGuid()  
$ChangeDate = (Get-Date).AddDays(+1).ToString('MM/dd/yyyy')
$CsvFile = "C:\temp\McAfeeHostNameList.csv"
$logDir = "C:\Logs"
$script:LogFile = "C:\temp\UninstallMcAfee.log"
$PrevLog = "C:\temp\UninstallMcAfeePrev.log"

# Local Logging
#################################
If(!(Test-Path $LogDir))
{
    New-Item -Path $LogDir -ItemType Directory
}
If(Test-Path $script:LogFile)
{
    Remove-Item $PrevLog -Force
    Rename-Item $script:LogFile -NewName "UninstallMcAfeePrev.log" -Force
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

Function RemoveMcAfeeFromTaskScheduler {
    # Loop through the file list containing hostname to uninstall McAfee  
    # Import the CSV file. 
    Try {$SERVERS = Import-Csv $CsvFile} 
    Catch 
    { 
        Write-Host "Invalid CSV file $CsvFile!!" -ForegroundColor Red -BackgroundColor Black 
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
                $ServerFiles = "\\$SERVER\c$\Temp"
                # If C:\Temp folder does not exist, create it in the host machine. 
                If(!(Test-Path $ServerFiles))
                {
                    New-Item -Path $ServerFiles -ItemType Directory
                }

                $McAfeeFiles = "\\SERVER\SHARE\...\*"
                Copy-Item $McAfeeFiles -Destination $ServerFiles -Recurse

                Write-Log "Copied $McAfeeFiles to $ServerFiles"

                #Creates the new scheduled Task 
                &SCHTASKS /create /s $SERVER /TN "UninstallMcAfee" /SC "Once" /RU "domain\svc_dsk_auto" /RP "<password>" /ST "21:00" /SD $ChangeDate /TR "C:\Temp\Uninstall-McAfee_running.cmd" /f 

                # Log to local file 
                $output = "Successfully Created the Task Scheduler to remove McAfee at $SERVER"
                $status = "Success"
            }
            Catch{
                $output = "Failed to copy $SCRIPT to $SERVER to uninstall McAfee`n Exception Message: $($_.Exception.Message)."
                $status ="Fail"
            }
            Finally
            {
                Write-Host $output -ForegroundColor Yellow
                Write-Log $output
                Log_ToSplunk -Message $output -Status $status
            }
        }
        Else{
            # Log to local file 
            Write-Log "$SERVER is offline. Failed to create the Task Scheduler to remove McAfee"
        }
    }
}   
# ----------------------------------------------------------------------------------------------
# Script Starts
# ----------------------------------------------------------------------------------------------
Log_ToSplunk -Message "Script Starting." -Type "Informational Begin" -Status "" -ID "$Script:UID"
RemoveMcAfeeFromTaskScheduler
Log_ToSplunk -Message "Script Ending." -Type "Informational End" -Status "" -ID "$Script:UID"
# ----------------------------------------------------------------------------------------------
# Script Ends
# ----------------------------------------------------------------------------------------------
