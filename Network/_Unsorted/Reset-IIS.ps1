# LEGAL
<# LICENSE
    MIT License, Copyright 2001 Richard Smith

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
    Reset-IIS.ps1

.SYNOPSIS
  GUI Tool to reset IIS services on srv
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  01/01/2001
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (01/01/2001)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    GUI Tool to reset IIS services on srv

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
$Script:ProductName = "Reset-IIS" #Fill this in. Do not put the "TEAM_" prefix
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
  Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}

function Reset-IIS-Services
{
    [Cmdletbinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $Server
    )
    Invoke-Command -ComputerName $Server -ScriptBlock {iisreset.exe /RESTART} -Credential $script:credentials
    if($?)
    {
        Log_ToSplunk -Message "$server - IIS Services Reset"
        return $Server + " - IIS Services Reset"
    }
    else 
    {
        Log_ToSplunk -Message "$server - IIS Services could not be reset"
        return $Server + " - IIS Services coult not be reset"
    }
}

function Call-Information_Dialogue_psf($message) {

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
	$formInformation = New-Object 'System.Windows.Forms.Form'
	$MessageLabel = New-Object 'System.Windows.Forms.Label'
	$buttonOK = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$formInformation_Load={
		#TODO: Initialize Form Controls here
		$MessageLabel.Text = $message
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formInformation.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$formInformation.remove_Load($formInformation_Load)
			$formInformation.remove_Load($Form_StateCorrection_Load)
			$formInformation.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formInformation.SuspendLayout()
	#
	# formInformation
	#
	$formInformation.Controls.Add($MessageLabel)
	$formInformation.Controls.Add($buttonOK)
	$formInformation.AcceptButton = $buttonOK
	$formInformation.AutoScaleDimensions = '6, 13'
	$formInformation.AutoScaleMode = 'Font'
	$formInformation.ClientSize = '314, 121'
	$formInformation.FormBorderStyle = 'FixedDialog'
	$formInformation.MaximizeBox = $False
	$formInformation.MinimizeBox = $False
	$formInformation.Name = 'formInformation'
	$formInformation.StartPosition = 'CenterScreen'
	$formInformation.Text = 'Information'
	$formInformation.add_Load($formInformation_Load)
	#
	# MessageLabel
	#
	$MessageLabel.AutoSize = $True
	$MessageLabel.Location = '13, 13'
	$MessageLabel.Name = 'MessageLabel'
	$MessageLabel.Size = '0, 13'
	$MessageLabel.TabIndex = 1
	#
	# buttonOK
	#
	$buttonOK.Anchor = 'Bottom, Right'
	$buttonOK.DialogResult = 'OK'
	$buttonOK.Location = '227, 86'
	$buttonOK.Name = 'buttonOK'
	$buttonOK.Size = '75, 23'
	$buttonOK.TabIndex = 0
	$buttonOK.Text = '&OK'
	$buttonOK.UseVisualStyleBackColor = $True
	$formInformation.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formInformation.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formInformation.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formInformation.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formInformation.ShowDialog()

}

function Call-Reset-IIS_psf {

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
	$formResetIIS = New-Object 'System.Windows.Forms.Form'
	$groupbox1 = New-Object 'System.Windows.Forms.GroupBox'
	$checkboxPD0DMIIS05 = New-Object 'System.Windows.Forms.CheckBox'
	$checkboxPD0DMIIS04 = New-Object 'System.Windows.Forms.CheckBox'
	$checkboxPD0DMIIS03 = New-Object 'System.Windows.Forms.CheckBox'
	$buttonResetSelectedIISServ = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$formResetIIS_Load={
		#TODO: Initialize Form Controls here
		
	}
	
	
	$buttonResetSelectedIISServ_Click={
		#TODO: Place custom script here
		$computers = @()
		if ($checkboxPD0DMIIS03.Checked -eq $true)
		{
			$computers += "srv"
		}
		if ($checkboxPD0DMIIS04.Checked -eq $true)
		{
			$computers += "srv"
		}
		if ($checkboxPD0DMIIS05.Checked -eq $true)
		{
			$computers += "srv"
		}
		
		$status = @()
		foreach ($computer in $computers)
		{
			$status += Reset-IIS-Services -Server $computer
		}
		
		Call-Information_Dialogue_psf $status
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formResetIIS.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonResetSelectedIISServ.remove_Click($buttonResetSelectedIISServ_Click)
			$formResetIIS.remove_Load($formResetIIS_Load)
			$formResetIIS.remove_Load($Form_StateCorrection_Load)
			$formResetIIS.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formResetIIS.SuspendLayout()
	$groupbox1.SuspendLayout()
	#
	# formResetIIS
	#
	$formResetIIS.Controls.Add($groupbox1)
	$formResetIIS.Controls.Add($buttonResetSelectedIISServ)
	$formResetIIS.AutoScaleDimensions = '6, 13'
	$formResetIIS.AutoScaleMode = 'Font'
	$formResetIIS.ClientSize = '144, 210'
	$formResetIIS.FormBorderStyle = 'FixedSingle'
	$formResetIIS.MaximizeBox = $False
	$formResetIIS.MinimizeBox = $False
	$formResetIIS.Name = 'formResetIIS'
	$formResetIIS.Text = 'Reset-IIS'
	$formResetIIS.add_Load($formResetIIS_Load)
	#
	# groupbox1
	#
	$groupbox1.Controls.Add($checkboxPD0DMIIS05)
	$groupbox1.Controls.Add($checkboxPD0DMIIS04)
	$groupbox1.Controls.Add($checkboxPD0DMIIS03)
	$groupbox1.BackColor = 'Transparent'
	$groupbox1.Location = '12, 12'
	$groupbox1.Name = 'groupbox1'
	$groupbox1.Size = '125, 112'
	$groupbox1.TabIndex = 2
	$groupbox1.TabStop = $False
	$groupbox1.Text = 'Servers'
	#
	# checkboxPD0DMIIS05
	#
	$checkboxPD0DMIIS05.Location = '7, 80'
	$checkboxPD0DMIIS05.Name = 'checkboxPD0DMIIS05'
	$checkboxPD0DMIIS05.Size = '104, 24'
	$checkboxPD0DMIIS05.TabIndex = 2
	$checkboxPD0DMIIS05.Text = 'srv'
	$checkboxPD0DMIIS05.UseVisualStyleBackColor = $True
	#
	# checkboxPD0DMIIS04
	#
	$checkboxPD0DMIIS04.Location = '7, 50'
	$checkboxPD0DMIIS04.Name = 'checkboxPD0DMIIS04'
	$checkboxPD0DMIIS04.Size = '104, 24'
	$checkboxPD0DMIIS04.TabIndex = 1
	$checkboxPD0DMIIS04.Text = 'srv'
	$checkboxPD0DMIIS04.UseVisualStyleBackColor = $True
	#
	# checkboxPD0DMIIS03
	#
	$checkboxPD0DMIIS03.Location = '7, 20'
	$checkboxPD0DMIIS03.Name = 'checkboxPD0DMIIS03'
	$checkboxPD0DMIIS03.Size = '104, 24'
	$checkboxPD0DMIIS03.TabIndex = 0
	$checkboxPD0DMIIS03.Text = 'srv'
	$checkboxPD0DMIIS03.UseVisualStyleBackColor = $True
	#
	# buttonResetSelectedIISServ
	#
	$buttonResetSelectedIISServ.Location = '12, 130'
	$buttonResetSelectedIISServ.Name = 'buttonResetSelectedIISServ'
	$buttonResetSelectedIISServ.Size = '119, 69'
	$buttonResetSelectedIISServ.TabIndex = 1
	$buttonResetSelectedIISServ.Text = 'Reset Selected IIS Servers'
	$buttonResetSelectedIISServ.UseVisualStyleBackColor = $True
	$buttonResetSelectedIISServ.add_Click($buttonResetSelectedIISServ_Click)
	$groupbox1.ResumeLayout()
	$formResetIIS.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formResetIIS.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formResetIIS.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formResetIIS.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formResetIIS.ShowDialog()

}

# Variables
#################################
$username = "domain\svc_IISAutomation"
$password = ConvertTo-SecureString "<password>" -asplaintext -Force

$script:credentials = New-Object System.Management.Automation.PSCredential($username,$password)

#$script:credentials = Get-Credential -Message "Enter Your Administrator Credentials"

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

Call-Reset-IIS_psf

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit