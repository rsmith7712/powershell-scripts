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
    Splunk_Maintenance.ps1

.SYNOPSIS
  GUI tool that can: 
    1) Get the status of the splunk service of target computer
    2) Restart Splunk service on target computer
    3) Re-install/Install splunk agent on target computer
  
.NOTES
  Version:        1.1
  Edited By:      user26
  Creation Date:  10/17/2018
  Purpose/Change: Installer was missing deploymentclient.conf per Security. Updated installer.
  
.HISTORY
  Version:        1.0 (09/06/2018 - user22)
  Purpose/Change: Initial Script Development
  Version:        1.0 (09/06/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    GUI tool that can:
        1) Get the status of the splunk service of target computer
        2) Restart Splunk service on target computer
        3) Re-install/Install splunk agent on target computer

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Functions to hide/show console window.  Found here: https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5/view/Discussions
#################################
Add-Type -Name WinAPI -Namespace Native -MemberDefinition '
[DllImport("Kernel32.dll")] 
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

function Show-Console
{
	$ConsoleHandle = [Native.WinAPI]::GetConsoleWindow()
	[Native.WinAPI]::ShowWindow($ConsoleHandle, 5) | Out-Null
}

function Hide-Console
{
	$ConsoleHandle = [Native.WinAPI]::GetConsoleWindow()
	[Native.WinAPI]::ShowWindow($ConsoleHandle, 0) | Out-Null
}
#################################

# Initializations
#################################
Hide-Console
$Script:ProductName = "Splunk_Maintenance" #Fill this in. Do not put the "TEAM_" prefix
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

	$SB = {
		param($uri,$header,$body)
		Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
	}

	$job = Start-Job -scriptblock $SB -argumentlist @($uri,$header,$body) | Out-Null
	$timeout = 10
	Wait-Job $job -Timeout $timeout
	Stop-Job $job
	Receive-Job $job
	Remove-Job $job
}

function Write_Log
{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,
        Position=0)]
        $Message
    )
    $timestamp = Get-Date -Format MM/dd/yy-hh:mm:ss
    $LogBox.AppendText("$timestamp - " + $Message + "`r`n")
}

function Get_Service
{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,
        Position=0)]
        $computer
    )
    Write_Log -Message "Getting Splunk service status for $computer"
    Log_ToSplunk "Getting Splunk service status for $computer"
    if(Test-Connection -ComputerName $computer -Count 1 -Quiet)
    {
        $result = Invoke-Command -ComputerName $computer -ScriptBlock {(Get-Service -Name "SplunkForwarder").Status} -Credential $script:Credential
        $status = $result.Value
        if($status -eq $null)
        {
            Log_ToSplunk -Message "Splunk service not found on $computer"
            Write_Log -Message "Splunk service not found on $computer"
            return "not_installed"
        }
        else 
        {
            Log_ToSplunk -Message "Splunk status on $($computer): $status"
            Write_Log -Message "Splunk status on $($computer): $status"
            return $status
        }
    }
    else 
    {
        Write_Log -Message "$computer - Offline"
        $status = "Offline"
        return $status
    }
}

function Restart_Service
{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,
        Position=0)]
        $computer
    )
    Log_ToSplunk -Message "Restarting Splunk service on $computer"
    Write_Log -Message "Restarting Splunk service on $computer"
    try 
    {
        Invoke-Command -ComputerName $computer -ScriptBlock {Restart-Service -Name "SplunkForwarder" -Force} -Credential $script:Credential
    }
    catch 
    {
        Log_ToSplunk -Message "Unable to start/restart Splunk service on $computer" -Status "fail"
        Write_Log -Message "Unable to start/restart Splunk service on $computer"
        return "Error"
    }
    Log_ToSplunk -Message "Splunk service was started/restarted on $computer"
    Write_Log -Message "Splunk service was started/restarted on $computer"
    return "Started"
}

function Install_Splunk
{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,
        Position=0)]
        $Computer,

        [parameter(Mandatory=$false,
        Position=1)]
        $Location = "PROD"
	)
	
	$IPaddress = ([System.Net.Dns]::GetHostByName($Computer).AddressList[0]).IPAddressToString
	$IPSplit = $IPAddress.split(".")
	$1oct = $IPSplit[0]
	$2oct = $IPSplit[1]
	$3oct = $IPSplit[2]
	$IP = $1oct + "." + $2oct + "." + $3oct

	if(($IP -eq "10.150.42") -or ($IP -eq "192.168.168"))
	{
		$Location = "DMZ"
	}

    $SB = {
        Start-Process msiexec.exe -ArgumentList '/i "c:\Software\SplunkForwarder\splunkforwarder-6.5.9-eb980bc2467e-x64-release.msi" LAUNCHSPLUNK=0 AGREETOLICENSE=Yes SERVICESTARTTYPE=auto /quiet' -Wait
        #Write_Log -Message "Agent installed, running post tasks"
        if((Get-Service -Name "SplunkForwarder").Status -eq "Running")
        {
            Stop-Service -Name "SplunkForwarder" -Force
        }
		Copy-Item -Path "C:\Software\SplunkForwarder\server.conf" -Destination "C:\Program Files\SplunkUniversalForwarder\etc\system\local\" -Force
		Copy-Item -Path "C:\Software\SplunkForwarder\deploymentclient.conf" -Destination "C:\Program Files\SplunkUniversalForwarder\etc\system\local\" -Force
        #Write_Log -Message "Setting service to start automatically"
        Set-Service -Name "SplunkForwarder" -StartupType Automatic
        #Write_Log -Message "Starting agent"
        Start-Service -Name "SplunkForwarder"
    }

    Log_ToSplunk -Message "Installing Splunk Agent on $computer"
    Write_Log -Message "Installing Splunk Agent on $computer"

    if($Location -eq "PROD")
    {
        Write_Log -Message "Network location for this install is PROD"
        $drive = New-PSDrive -Name "P" -PSProvider FileSystem -Root "\\$computer\C$\Software" -Credential $script:Credential
        Copy-Item -Path "\\SERVER\SHARE\...\SplunkForwarder" -Destination "P:\" -Recurse -Force
        Remove-PSDrive $drive
    }
    elseif($Location -eq "DMZ")
    {
        Write_Log -Message "Network location for this install is DMZ"
        $drive = New-PSDrive -Name "P" -PSProvider FileSystem -Root "\\$computer\C$\Software" -Credential $script:Credential
        Copy-Item -Path "\\0.0.0.0\c$\...\SplunkForwarder" -Destination "P:\" -Recurse -Force
        Remove-PSDrive $drive
    }
    elseif($Location -eq "ENG") 
    {
        Write_Log -Message "Network location for this install is ENG"
        $drive = New-PSDrive -Name "P" -PSProvider FileSystem -Root "\\$computer\C$\Software" -Credential $script:Credential
        Copy-Item -Path "\\SERVER\SHARE\...\SplunkForwarder" -Destination "P:\" -Recurse -Force
        Remove-PSDrive $drive
    }

    try 
    {
        Invoke-Command -ComputerName $Computer -ScriptBlock $SB -Credential $script:Credential
    }
    catch 
    {
        Log_ToSplunk -Message "Unable to install Splunk Agent on $computer" -Status "fail"
        Write_Log -Message "Unable to install Splunk Agent on $computer" 
        return "Error"
    }
    Log_ToSplunk -Message "Splunk Agent installed on $computer"
    Write_Log -Message "Splunk Agent installed on $computer"
    return "Installed"
}

function Uninstall_Splunk
{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,
        Position=0)]
        $Computer
    )
    $SB = {
        $GUID = (Get-WmiObject -Class Win32_Product | Where-Object {$_.name -eq "UniversalForwarder"}).IdentifyingNumber
        Start-Process msiexec.exe -ArgumentList "/x $GUID /qn /norestart" -Wait
    }

    Log_ToSplunk -Message "Uninstalling Splunk agent on $Computer"
    Write_Log -Message "Uninstalling Splunk agent on $Computer"

    try
    {
        Invoke-Command -ComputerName $Computer -ScriptBlock $SB -Credential $script:Credential
    }
    catch
    {
        Log_ToSplunk -Message "Unable to uninstall Splunk agent on $Computer" -Status "fail"
        Write_Log -Message "Unable to uninstall Splunk agent on $Computer"
        return "Error"
    }
    Log_ToSplunk -Message "Splunk agent uninstalled succesfully from $Computer"
    Write_Log -Message "Splunk agent uninstalled succesfully from $Computer"
    return "Uninstalled"
}

function Call-Splunk_Maintenance_psf {

	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=0.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Data, Version=0.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Drawing, Version=0.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$formSplunkMaintenance = New-Object 'System.Windows.Forms.Form'
	$buttonReInstallSplunk = New-Object 'System.Windows.Forms.Button'
	$buttonInstallSplunk = New-Object 'System.Windows.Forms.Button'
	$buttonStartRestartSplunk = New-Object 'System.Windows.Forms.Button'
	$labelTargetComputer = New-Object 'System.Windows.Forms.Label'
	$groupbox1 = New-Object 'System.Windows.Forms.GroupBox'
	$labelServiceStatus = New-Object 'System.Windows.Forms.Label'
	$labelInstalledStatus = New-Object 'System.Windows.Forms.Label'
	$labelService = New-Object 'System.Windows.Forms.Label'
	$labelInstalled = New-Object 'System.Windows.Forms.Label'
	$LogBox = New-Object 'System.Windows.Forms.TextBox'
	$inputBox = New-Object 'System.Windows.Forms.TextBox'
	$buttonGetStatus = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	$SplunkInstallStatus = ""
	$SplunkServiceStatus = ""
	
	function Write_Log
	{
		[CmdletBinding()]
		Param (
			[parameter(Mandatory = $true,
					   Position = 0)]
			$Message
		)
		$timestamp = Get-Date -Format MM/dd/yy-hh:mm:ss
		$LogBox.AppendText("$timestamp - " + $Message + "`r`n")
	}
	
	$formSplunkMaintenance_Load={
		#TODO: Initialize Form Controls here
		Write_Log -Message "Splunk Maintenance Version 1.0"
		$buttonStartRestartSplunk.Enabled = $false
		$buttonInstallSplunk.Enabled = $false
		$buttonReInstallSplunk.Enabled = $false
	}
	
	$InputBox_TextChanged={
		$labelInstalledStatus.Text = ""
		$labelServiceStatus.Text = ""
		$SplunkInstallStatus = ""
		$SplunkServiceStatus = ""
		$buttonStartRestartSplunk.Enabled = $false
		$buttonInstallSplunk.Enabled = $false
		$buttonReInstallSplunk.Enabled = $false
	}
	
	$buttonGetStatus_Click = {
		$target = $inputBox.Text.ToUpper()
		#Write_Log -Message "Getting status of $target"
		$result = Get_Service -computer $target
		If ($result -eq "Offline")
		{
			$labelInstalledStatus.Text = "OFFLINE"
			$labelInstalledStatus.ForeColor = 'Red'
			$labelServiceStatus.Text = "OFFLINE"
			$labelServiceStatus.ForeColor = 'Red'
		}
		elseif ($result -eq "not_installed")
		{
			$labelInstalledStatus.Text = "NOT INSTALLED"
			$labelInstalledStatus.ForeColor = 'Red'
			$labelServiceStatus.Text = "NOT INSTALLED"
			$labelServiceStatus.ForeColor = 'Red'
			$SplunkInstallStatus = "NotInstalled"
			
			$buttonInstallSplunk.Enabled = $true
		}
		elseif ($result -ne $null)
		{
			$labelInstalledStatus.Text = "INSTALLED"
			$labelInstalledStatus.ForeColor = 'Green'
			$labelServiceStatus.Text = $result
			if ($result -eq "Running")
			{
				$labelServiceStatus.ForeColor = 'Green'
			}
			elseif ($result -eq "Stopped")
			{
				$labelServiceStatus.ForeColor = 'Red'
			}
			else
			{
				$labelServiceStatus.ForeColor = 'Orange'
			}
			$SplunkInstallStatus = "Installed"
			$SplunkServiceStatus = $result
			
			$buttonStartRestartSplunk.Enabled = $true
			$buttonReInstallSplunk.Enabled = $true
		}
	}
	
	$buttonStartRestartSplunk_Click={
		$target = $inputBox.Text.ToUpper()
		$result = Restart_Service -computer $target
		if ($result -eq "Started")
		{
			$labelServiceStatus.Text = "Running"
			$labelServiceStatus.ForeColor = 'Green'
		}
		elseif ($result -eq "Error")
		{
			$labelServiceStatus.Text = "Error"
			$labelServiceStatus.ForeColor = 'Red'
		}
	}
	
	$buttonInstallSplunk_Click={
		$target = $inputBox.Text.ToUpper()
		$result = Install_Splunk -Computer $target
		if($result -eq "Installed")
		{
			Invoke-Command -ScriptBlock $buttonGetStatus_Click
			<#
			$labelInstalledStatus.Text = "INSTALLED"
			$labelInstalledStatus.ForeColor = 'Green'
			$labelServiceStatus.Text = "Running"
			$labelServiceStatus.ForeColor = 'Green'
			$buttonInstallSplunk.Enabled = $false
			$buttonReInstallSplunk.Enabled = $true
			$buttonStartRestartSplunk.Enabled = $true
			#>
		}
		elseif ($result -eq "Error")
		{
			$labelInstalledStatus.Text = "ERROR INSTALLING"
			$labelInstalledStatus.ForeColor = 'Red'
		}
	}
	
	$buttonReInstallSplunk_Click={
		$target = $inputBox.Text.ToUpper()
		$uninstall = Uninstall_Splunk -Computer $target
		if ($uninstall -eq "Uninstalled")
		{
			Invoke-Command -ScriptBlock $buttonGetStatus_Click
			$result = Install_Splunk -Computer $target
			if ($result -eq "Installed")
			{
				Invoke-Command -ScriptBlock $buttonGetStatus_Click
				<#
				$labelInstalledStatus.Text = "INSTALLED"
				$labelInstalledStatus.ForeColor = 'Green'
				$labelServiceStatus.Text = "Running"
				$labelServiceStatus.ForeColor = 'Green'
				$buttonInstallSplunk.Enabled = $false
				$buttonReInstallSplunk.Enabled = $true
				$buttonStartRestartSplunk.Enabled = $true
				#>
			}
			elseif ($result -eq "Error")
			{
				$labelInstalledStatus.Text = "ERROR INSTALLING"
				$labelInstalledStatus.ForeColor = 'Red'
			}
		}
		elseif ($uninstall -eq "Error")
		{
			$labelInstalledStatus.Text = "ERROR UNINSTALLING"
			$labelInstalledStatus.ForeColor = 'Red'
		}
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formSplunkMaintenance.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonReInstallSplunk.remove_Click($buttonReInstallSplunk_Click)
			$buttonInstallSplunk.remove_Click($buttonInstallSplunk_Click)
			$buttonStartRestartSplunk.remove_Click($buttonStartRestartSplunk_Click)
			$inputBox.remove_TextChanged($InputBox_TextChanged)
			$buttonGetStatus.remove_Click($buttonGetStatus_Click)
			$formSplunkMaintenance.remove_Load($formSplunkMaintenance_Load)
			$formSplunkMaintenance.remove_Load($Form_StateCorrection_Load)
			$formSplunkMaintenance.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formSplunkMaintenance.SuspendLayout()
	$groupbox1.SuspendLayout()
	#
	# formSplunkMaintenance
	#
	$formSplunkMaintenance.Controls.Add($buttonReInstallSplunk)
	$formSplunkMaintenance.Controls.Add($buttonInstallSplunk)
	$formSplunkMaintenance.Controls.Add($buttonStartRestartSplunk)
	$formSplunkMaintenance.Controls.Add($labelTargetComputer)
	$formSplunkMaintenance.Controls.Add($groupbox1)
	$formSplunkMaintenance.Controls.Add($LogBox)
	$formSplunkMaintenance.Controls.Add($inputBox)
	$formSplunkMaintenance.Controls.Add($buttonGetStatus)
	$formSplunkMaintenance.AutoScaleDimensions = '6, 13'
	$formSplunkMaintenance.AutoScaleMode = 'Font'
	$formSplunkMaintenance.ClientSize = '784, 511'
	$formSplunkMaintenance.FormBorderStyle = 'FixedSingle'
	$formSplunkMaintenance.MaximizeBox = $False
	$formSplunkMaintenance.Name = 'formSplunkMaintenance'
	$formSplunkMaintenance.Text = 'Splunk Maintenance'
	$formSplunkMaintenance.add_Load($formSplunkMaintenance_Load)
	#
	# buttonReInstallSplunk
	#
	$buttonReInstallSplunk.Location = '448, 221'
	$buttonReInstallSplunk.Name = 'buttonReInstallSplunk'
	$buttonReInstallSplunk.Size = '100, 50'
	$buttonReInstallSplunk.TabIndex = 7
	$buttonReInstallSplunk.Text = 'Re-Install Splunk'
	$buttonReInstallSplunk.UseVisualStyleBackColor = $True
	$buttonReInstallSplunk.add_Click($buttonReInstallSplunk_Click)
	#
	# buttonInstallSplunk
	#
	$buttonInstallSplunk.Location = '342, 221'
	$buttonInstallSplunk.Name = 'buttonInstallSplunk'
	$buttonInstallSplunk.Size = '100, 50'
	$buttonInstallSplunk.TabIndex = 6
	$buttonInstallSplunk.Text = 'Install Splunk'
	$buttonInstallSplunk.UseVisualStyleBackColor = $True
	$buttonInstallSplunk.add_Click($buttonInstallSplunk_Click)
	#
	# buttonStartRestartSplunk
	#
	$buttonStartRestartSplunk.Location = '236, 222'
	$buttonStartRestartSplunk.Name = 'buttonStartRestartSplunk'
	$buttonStartRestartSplunk.Size = '100, 50'
	$buttonStartRestartSplunk.TabIndex = 5
	$buttonStartRestartSplunk.Text = 'Start/Restart Splunk'
	$buttonStartRestartSplunk.UseVisualStyleBackColor = $True
	$buttonStartRestartSplunk.add_Click($buttonStartRestartSplunk_Click)
	#
	# labelTargetComputer
	#
	$labelTargetComputer.AutoSize = $True
	$labelTargetComputer.Location = '348, 24'
	$labelTargetComputer.Name = 'labelTargetComputer'
	$labelTargetComputer.Size = '89, 13'
	$labelTargetComputer.TabIndex = 4
	$labelTargetComputer.Text = 'Target Computer:'
	#
	# groupbox1
	#
	$groupbox1.Controls.Add($labelServiceStatus)
	$groupbox1.Controls.Add($labelInstalledStatus)
	$groupbox1.Controls.Add($labelService)
	$groupbox1.Controls.Add($labelInstalled)
	$groupbox1.Location = '78, 111'
	$groupbox1.Name = 'groupbox1'
	$groupbox1.Size = '628, 92'
	$groupbox1.TabIndex = 3
	$groupbox1.TabStop = $False
	$groupbox1.Text = 'Status'
	#
	# labelServiceStatus
	#
	$labelServiceStatus.AutoSize = $True
	$labelServiceStatus.Font = 'Arial, 11.25pt'
	$labelServiceStatus.Location = '153, 55'
	$labelServiceStatus.Name = 'labelServiceStatus'
	$labelServiceStatus.Size = '0, 17'
	$labelServiceStatus.TabIndex = 3
	#
	# labelInstalledStatus
	#
	$labelInstalledStatus.AutoSize = $True
	$labelInstalledStatus.Font = 'Arial, 11.25pt'
	$labelInstalledStatus.Location = '153, 20'
	$labelInstalledStatus.Name = 'labelInstalledStatus'
	$labelInstalledStatus.Size = '0, 17'
	$labelInstalledStatus.TabIndex = 2
	#
	# labelService
	#
	$labelService.AutoSize = $True
	$labelService.Font = 'Arial, 11.25pt'
	$labelService.Location = '86, 55'
	$labelService.Name = 'labelService'
	$labelService.Size = '61, 17'
	$labelService.TabIndex = 1
	$labelService.Text = 'Service:'
	#
	# labelInstalled
	#
	$labelInstalled.AutoSize = $True
	$labelInstalled.Font = 'Arial, 11.25pt'
	$labelInstalled.Location = '82, 20'
	$labelInstalled.Name = 'labelInstalled'
	$labelInstalled.Size = '65, 17'
	$labelInstalled.TabIndex = 0
	$labelInstalled.Text = 'Installed:'
	#
	# LogBox
	#
	$LogBox.Font = 'Arial, 8.25pt'
	$LogBox.Location = '13, 298'
	$LogBox.Multiline = $True
	$LogBox.Name = 'LogBox'
	$LogBox.ReadOnly = $True
	$LogBox.ScrollBars = 'Vertical'
	$LogBox.Size = '759, 201'
	$LogBox.TabIndex = 2
	#
	# inputBox
	#
	$inputBox.Font = 'Arial, 12pt'
	$inputBox.Location = '312, 45'
	$inputBox.Name = 'inputBox'
	$inputBox.Size = '160, 26'
	$inputBox.TabIndex = 1
	$inputBox.TextAlign = 'Center'
	$inputBox.add_TextChanged($InputBox_TextChanged)
	#
	# buttonGetStatus
	#
	$buttonGetStatus.Location = '355, 77'
	$buttonGetStatus.Name = 'buttonGetStatus'
	$buttonGetStatus.Size = '75, 23'
	$buttonGetStatus.TabIndex = 0
	$buttonGetStatus.Text = 'Get-Status'
	$buttonGetStatus.UseVisualStyleBackColor = $True
	$buttonGetStatus.add_Click($buttonGetStatus_Click)
	$groupbox1.ResumeLayout()
	$formSplunkMaintenance.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formSplunkMaintenance.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formSplunkMaintenance.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formSplunkMaintenance.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formSplunkMaintenance.ShowDialog()

}

# Variables
#################################

$username = "domain\svc_SplunkAutomation"
$password = ConvertTo-SecureString "<password>" -AsPlainText -Force

$script:Credential = New-Object System.Management.Automation.PSCredential($username,$password) # enter credential information here
    
# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

Call-Splunk_Maintenance_psf

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit