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
    Clearpass_API.ps1

.SYNOPSIS
  uses the clearpass REST API to add network devices into the clearpass device database
   
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  08/06/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    uses the clearpass REST API to add network devices into the clearpass device database

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Functions to hide/show console window.  Found here: https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5/view/Discussions
###############################################################
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
###############################################################

# Initializations
#################################
#Hide-Console
$Script:ProductName = "Clearpass_DeviceAdd" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "Inquire" #Maybe change to "SilentlyContinue" for Production.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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

	$job = Start-Job -scriptblock $SB -argumentlist @($uri,$header,$body)
	$timeout = 10
	Wait-Job $job -Timeout $timeout
	Stop-Job $job
	Receive-Job $job
	Remove-Job $job
}


function Get-Auth
{
    $url = "https://clearpass.example.com/api/oauth"
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $payload = @{
        grant_type = 'password'
        username = 'apiautomation'
        password = '<password>'
        client_id = 'Automation'
    }
    $payload = $payload | ConvertTo-Json
    $result = Invoke-WebRequest -Uri $url -Method Post -Headers $header -Body $payload
    $result = $result | ConvertFrom-Json
    return "Bearer " + $result.access_token
}

function Check-NetDevice
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        [string]$UFO_NUMBER
    )

    $uri = 'https://clearpass.example.com/api/network-device?filter=%7B%22name%22%3A%7B%22%24contains%22%3A%22' + $UFO_NUMBER + '%22%7D%7D&sort=%2Bid&offset=0&limit=20&calculate_count=false'
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.add('Authorization', $script:authToken)
    $header.Add('Accept', 'application/json')

    $devices = Invoke-webrequest -Uri $uri -Method Get -Headers $header
    $devices = $devices | ConvertFrom-Json
    $devices
    return $devices._embedded.items.name
}

function Add-NetDevice
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        position=0)]
        $name,

        [parameter(Mandatory=$true,
        position=1)]
        $description,

        [parameter(Mandatory=$true,
        position=2)]
        $ip_address,

        [parameter(Mandatory=$false,
        position=3)]
        $radius_secret,

        [parameter(Mandatory=$false,
        position=4)]
        $tacacs_secret,

        [parameter(Mandatory=$true,
        position=5)]
        $device_vendor,

        [parameter(Mandatory=$true,
        position=6)]
        $device_type
    )
    $uri = 'https://clearpass.example.com/api/network-device'
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.Add('Accept', 'application/json')
    $header.add('Authorization', $script:authToken)

    if($tacacs_secret -eq $null)
    {
        $payload = @{
            name = $name
            description = $description
            ip_address = $ip_address
            radius_secret = $radius_secret
            tacacs_secret = ""
            vendor_name = $device_vendor
            coa_capable = 'true'
            coa_port = '3799'
            attributes = @{
                Location = 'Retail'
                'Device Type' = $device_type
                'Device Vendor' = $device_vendor
            }
        }
    }

    if($radius_secret -eq $null)
    {
        $payload = @{
            name = $name
            description = $description
            ip_address = $ip_address
            radius_secret = ""
            tacacs_secret = $tacacs_secret
            vendor_name = $device_vendor
            coa_capable = 'true'
            coa_port = '3799'
            attributes = @{
                Location = 'Retail'
                'Device Type' = $device_type
                'Device Vendor' = $device_vendor
            }
        }
    }

    if(($radius_secret -eq $null) -and ($tacacs_secret -eq $null))
    {
        $payload = @{
            name = $name
            description = $description
            ip_address = $ip_address
            radius_secret = ""
            tacacs_secret = ""
            vendor_name = $device_vendor
            coa_capable = 'true'
            coa_port = '3799'
            attributes = @{
                Location = 'Retail'
                'Device Type' = $device_type
                'Device Vendor' = $device_vendor
            }
        }
    }

    $payload = $payload | ConvertTo-Json
    $send = Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $payload
    $send = $send | ConvertFrom-Json
    if(($send.id -eq $null) -or ($send.id -eq ""))
    {
        Log_ToSplunk -Message "Clearpass entry could not be made for $name" -Status "fail"
        return $false
    }
    else
    {
        Log_ToSplunk -Message "Clearpass entry made for $name with device id: $($send.id)" -Status "success"
        return $true
    }
}

function Call-Clearpass_API_psf {

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
	$formClearpass = New-Object 'System.Windows.Forms.Form'
	$groupBoxStatus = New-Object 'System.Windows.Forms.GroupBox'
	$apSwitchStatus = New-Object 'System.Windows.Forms.Label'
	$regSwitchStatus = New-Object 'System.Windows.Forms.Label'
	$labelAeroHiveAPs = New-Object 'System.Windows.Forms.Label'
	$labelRegisterSwitch = New-Object 'System.Windows.Forms.Label'
	$mgrSwitchStatus = New-Object 'System.Windows.Forms.Label'
	$labelManagerSwitch = New-Object 'System.Windows.Forms.Label'
	$groupBoxInput = New-Object 'System.Windows.Forms.GroupBox'
	$labelSiteName = New-Object 'System.Windows.Forms.Label'
	$cityInput = New-Object 'System.Windows.Forms.TextBox'
	$buttonGenerateClearpassEnt = New-Object 'System.Windows.Forms.Button'
	$labelUFO_NUMBER = New-Object 'System.Windows.Forms.Label'
	$inputBox = New-Object 'System.Windows.Forms.TextBox'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$formClearpass_Load={
		$buttonGenerateClearpassEnt.Enabled=$false
		
	}
	
	$buttonGenerateClearpassEnt_Click = {
		$mgrSwitchStatus.Text = "Processing..."
		$mgrSwitchStatus.ForeColor = 'Orange'
		$regSwitchStatus.Text = "Processing..."
		$regSwitchStatus.ForeColor = 'Orange'
		$apSwitchStatus.Text = "Processing..."
		$apSwitchStatus.ForeColor = 'Orange'
		$script:UFO_NUMBER = $inputBox.Text
		
		$deviceCheck = @()
		$deviceCheck += $script:UFO_NUMBER + "-MSW1"
		$deviceCheck += $script:UFO_NUMBER + "-RSW1"
		$deviceCheck += $script:UFO_NUMBER + "-APs"
		
		$devices = Check-NetDevice -UFO_NUMBER $script:UFO_NUMBER
		
		$existingDevices = @()
		foreach ($device in $devices)
		{
			if ($deviceCheck -contains $device)
			{
				$existingDevices += $device
			}
		}
		
		# base properties
		
		$2oct = $script:UFO_NUMBER.Substring(0,2)
		$3oct = $script:UFO_NUMBER.Substring(2, 2)
		if ($3oct.Substring(0, 1) -eq "0")
		{
			$3oct = $script:UFO_NUMBER.Substring(3,1)
		}
		
		$baseIP = "10." + $2oct + "." + $3oct + "."
		
		# mgr switch properties
		
		$mgrName = $script:UFO_NUMBER + "-MSW1"
		$mgrDesc = $script:UFO_NUMBER + " " + $cityInput.Text + " Manager Switch"
		$mgrIP = $baseIP + "226"
		
		# reg switch properties
		
		$regName = $script:UFO_NUMBER + "-RSW1"
		$regDesc = $script:UFO_NUMBER + " " + $cityInput.Text + " Register Switch"
		$regIP = $baseIP + "227"
		
		# AP properties
		
		$apName = $script:UFO_NUMBER + "-APs"
		$apDesc = $script:UFO_NUMBER + " " + $cityInput.Text + " APs"
		$apIP = $baseIP + "231-239"
		
		# add MGR switch entry
		if ($existingDevices -notcontains $mgrName)
		{
			$addmgr = Add-NetDevice -name $mgrName -description $mgrDesc -ip_address $mgrIP -tacacs_secret $script:tacacs -device_vendor "Juniper" -device_type "Switch"
			if ($addmgr -eq $true)
			{
				$mgrSwitchStatus.Text = "Clearpass entry made for $mgrName"
				$mgrSwitchStatus.ForeColor = 'Green'
			}
			elseif ($addmgr -eq $false)
			{
				$mgrSwitchStatus.Text = "Clearpass entry could not be made for $mgrName"
				$mgrSwitchStatus.ForeColor = 'Red'
			}
		}
		else
		{
			$mgrSwitchStatus.Text = "Entry already exists for this device"
		}
		
		# add REG switch entry
		if ($existingDevices -notcontains $regName)
		{
			$addreg = Add-NetDevice -name $regName -description $regDesc -ip_address $regIP -tacacs_secret $script:tacacs -device_vendor "Juniper" -device_type "Switch"
			if ($addreg -eq $true)
			{
				$regSwitchStatus.Text = "Clearpass entry made for $regName"
				$regSwitchStatus.ForeColor = 'Green'
			}
			elseif ($addreg -eq $false)
			{
				$regSwitchStatus.Text = "Clearpass entry could not be made for $regName"
				$regSwitchStatus.ForeColor = 'Red'
			}
		}
		else
		{
			$regSwitchStatus.Text = "Entry already exists for this device"
		}
		
		# add AP entry
		if ($existingDevices -notcontains $apName)
		{
			$addap = Add-NetDevice -name $apName -description $apDesc -ip_address $apIP -radius_secret $script:radius -device_vendor "Aerohive" -device_type "WLC"
			if ($addap -eq $true)
			{
				$apSwitchStatus.Text = "Clearpass entry made for $apName"
				$apSwitchStatus.ForeColor = 'Green'
			}
			elseif ($addap -eq $false)
			{
				$apSwitchStatus.Text = "Clearpass entry could not be made for $apName"
				$apSwitchStatus.ForeColor = 'Red'
			}
		}
		else
		{
			$apSwitchStatus.Text = "Entry already exists for this device"
		}
	}
	
	$inputBox_TextChanged={
		if ($inputBox.Text -ne "")
		{
			$buttonGenerateClearpassEnt.Enabled=$true
		}
		else
		{
			$buttonGenerateClearpassEnt.Enabled=$false
		}
		
		$mgrSwitchStatus.Text = ""
		$regSwitchStatus.Text = ""
		$apSwitchStatus.Text = ""
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formClearpass.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonGenerateClearpassEnt.remove_Click($buttonGenerateClearpassEnt_Click)
			$inputBox.remove_TextChanged($inputBox_TextChanged)
			$formClearpass.remove_Load($formClearpass_Load)
			$formClearpass.remove_Load($Form_StateCorrection_Load)
			$formClearpass.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formClearpass.SuspendLayout()
	$groupBoxInput.SuspendLayout()
	$groupBoxStatus.SuspendLayout()
	#
	# formClearpass
	#
	$formClearpass.Controls.Add($groupBoxStatus)
	$formClearpass.Controls.Add($groupBoxInput)
	$formClearpass.AutoScaleDimensions = '6, 13'
	$formClearpass.AutoScaleMode = 'Font'
	$formClearpass.ClientSize = '414, 280'
	$formClearpass.FormBorderStyle = 'FixedSingle'
	$formClearpass.MaximizeBox = $False
	$formClearpass.Name = 'formClearpass'
	$formClearpass.Text = 'Clearpass'
	$formClearpass.add_Load($formClearpass_Load)
	#
	# groupBoxStatus
	#
	$groupBoxStatus.Controls.Add($apSwitchStatus)
	$groupBoxStatus.Controls.Add($regSwitchStatus)
	$groupBoxStatus.Controls.Add($labelAeroHiveAPs)
	$groupBoxStatus.Controls.Add($labelRegisterSwitch)
	$groupBoxStatus.Controls.Add($mgrSwitchStatus)
	$groupBoxStatus.Controls.Add($labelManagerSwitch)
	$groupBoxStatus.Location = '13, 163'
	$groupBoxStatus.Name = 'groupBoxStatus'
	$groupBoxStatus.Size = '389, 110'
	$groupBoxStatus.TabIndex = 1
	$groupBoxStatus.TabStop = $False
	$groupBoxStatus.Text = 'Status'
	#
	# apSwitchStatus
	#
	$apSwitchStatus.AutoSize = $True
	$apSwitchStatus.Location = '89, 74'
	$apSwitchStatus.Name = 'apSwitchStatus'
	$apSwitchStatus.Size = '0, 13'
	$apSwitchStatus.TabIndex = 5
	#
	# regSwitchStatus
	#
	$regSwitchStatus.AutoSize = $True
	$regSwitchStatus.Location = '96, 49'
	$regSwitchStatus.Name = 'regSwitchStatus'
	$regSwitchStatus.Size = '0, 13'
	$regSwitchStatus.TabIndex = 4
	#
	# labelAeroHiveAPs
	#
	$labelAeroHiveAPs.AutoSize = $True
	$labelAeroHiveAPs.Location = '7, 74'
	$labelAeroHiveAPs.Name = 'labelAeroHiveAPs'
	$labelAeroHiveAPs.Size = '76, 13'
	$labelAeroHiveAPs.TabIndex = 3
	$labelAeroHiveAPs.Text = 'AeroHive APs:'
	#
	# labelRegisterSwitch
	#
	$labelRegisterSwitch.AutoSize = $True
	$labelRegisterSwitch.Location = '6, 49'
	$labelRegisterSwitch.Name = 'labelRegisterSwitch'
	$labelRegisterSwitch.Size = '84, 13'
	$labelRegisterSwitch.TabIndex = 2
	$labelRegisterSwitch.Text = 'Register Switch:'
	#
	# mgrSwitchStatus
	#
	$mgrSwitchStatus.AutoSize = $True
	$mgrSwitchStatus.Location = '100, 25'
	$mgrSwitchStatus.Name = 'mgrSwitchStatus'
	$mgrSwitchStatus.Size = '0, 13'
	$mgrSwitchStatus.TabIndex = 1
	#
	# labelManagerSwitch
	#
	$labelManagerSwitch.AutoSize = $True
	$labelManagerSwitch.Location = '7, 25'
	$labelManagerSwitch.Name = 'labelManagerSwitch'
	$labelManagerSwitch.Size = '87, 13'
	$labelManagerSwitch.TabIndex = 0
	$labelManagerSwitch.Text = 'Manager Switch:'
	#
	# groupBoxInput
	#
	$groupBoxInput.Controls.Add($labelSiteName)
	$groupBoxInput.Controls.Add($cityInput)
	$groupBoxInput.Controls.Add($buttonGenerateClearpassEnt)
	$groupBoxInput.Controls.Add($labelUFO_NUMBER)
	$groupBoxInput.Controls.Add($inputBox)
	$groupBoxInput.Location = '13, 13'
	$groupBoxInput.Name = 'groupBoxInput'
	$groupBoxInput.Size = '389, 144'
	$groupBoxInput.TabIndex = 0
	$groupBoxInput.TabStop = $False
	$groupBoxInput.Text = 'Input'
	#
	# labelSiteName
	#
	$labelSiteName.AutoSize = $True
	$labelSiteName.BackColor = 'Transparent'
	$labelSiteName.Location = '175, 12'
	$labelSiteName.Name = 'labelSiteName'
	$labelSiteName.Size = '56, 13'
	$labelSiteName.TabIndex = 4
	$labelSiteName.Text = 'Site Name'
	$labelSiteName.TextAlign = 'TopCenter'
	#
	# cityInput
	#
	$cityInput.Font = 'Microsoft Sans Serif, 12pt'
	$cityInput.Location = '175, 33'
	$cityInput.Name = 'cityInput'
	$cityInput.Size = '178, 26'
	$cityInput.TabIndex = 3
	$cityInput.TextAlign = 'Center'
	#
	# buttonGenerateClearpassEnt
	#
	$buttonGenerateClearpassEnt.Location = '135, 65'
	$buttonGenerateClearpassEnt.Name = 'buttonGenerateClearpassEnt'
	$buttonGenerateClearpassEnt.Size = '100, 55'
	$buttonGenerateClearpassEnt.TabIndex = 2
	$buttonGenerateClearpassEnt.Text = 'Generate Clearpass Entries'
	$buttonGenerateClearpassEnt.UseVisualStyleBackColor = $True
	$buttonGenerateClearpassEnt.add_Click($buttonGenerateClearpassEnt_Click)
	#
	# labelUFO_NUMBER
	#
	$labelUFO_NUMBER.AutoSize = $True
	$labelUFO_NUMBER.BackColor = 'Transparent'
	$labelUFO_NUMBER.Location = '48, 12'
	$labelUFO_NUMBER.Name = 'labelUFO_NUMBER'
	$labelUFO_NUMBER.Size = '72, 13'
	$labelUFO_NUMBER.TabIndex = 1
	$labelUFO_NUMBER.Text = 'UFO_NUMBER'
	$labelUFO_NUMBER.TextAlign = 'TopCenter'
	#
	# inputBox
	#
	$inputBox.Font = 'Microsoft Sans Serif, 12pt'
	$inputBox.Location = '48, 33'
	$inputBox.MaxLength = 4
	$inputBox.Name = 'inputBox'
	$inputBox.Size = '100, 26'
	$inputBox.TabIndex = 0
	$inputBox.TextAlign = 'Center'
	$inputBox.add_TextChanged($inputBox_TextChanged)
	$groupBoxStatus.ResumeLayout()
	$groupBoxInput.ResumeLayout()
	$formClearpass.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formClearpass.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formClearpass.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formClearpass.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formClearpass.ShowDialog()

}

# Variables
#################################

[string]$script:authToken = Get-Auth

$script:tacacs = 'UNnExcBen8%y6Neo'
$script:radius = 'AIiu4@dbnSJr'

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

Call-Clearpass_API_psf

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit