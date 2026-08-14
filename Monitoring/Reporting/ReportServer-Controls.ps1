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
    ReportServer-Controls.ps1

.SYNOPSIS
  Small GUI application to control ReportServer services on srv
 
.DESCRIPTION
  More in depth information.
 
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  05/24/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    More in depth information.

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
$Script:ProductName = "ReportServer-Controls" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.
#Hide-Console

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

function Call-ReportServer_Controls_psf ($cred) {

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
	$formReportServerControls = New-Object 'System.Windows.Forms.Form'
	$picturebox1 = New-Object 'System.Windows.Forms.PictureBox'
	$buttonRestart = New-Object 'System.Windows.Forms.Button'
	$buttonStop = New-Object 'System.Windows.Forms.Button'
	$buttonStart = New-Object 'System.Windows.Forms.Button'
	$groupbox1 = New-Object 'System.Windows.Forms.GroupBox'
	$status = New-Object 'System.Windows.Forms.Label'
	$labelStatus = New-Object 'System.Windows.Forms.Label'
	$buttonRefresh = New-Object 'System.Windows.Forms.Button'
	$buttonOK = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
    
    $computer = "srv"

    $formReportServerControls_Load={
        $servicestatus = Invoke-Command -ComputerName $computer -ScriptBlock { Get-Service -Name "ReportServer" } -Credential $cred
        if ($servicestatus.Status -eq "running")
        {
            $status.Text = $servicestatus.status
            $status.ForeColor = 'Green'
            $buttonStart.Enabled = $false
            $buttonStop.Enabled = $true
            $buttonRestart.Enabled = $true
        }
        else
        {
            $status.Text = $servicestatus.status
            $status.ForeColor = 'Red'
            $buttonStart.Enabled = $true
            $buttonStop.Enabled = $false
            $buttonRestart.Enabled = $false
        }
    }

    $buttonRefresh_Click={
        $servicestatus = Invoke-Command -ComputerName $computer -ScriptBlock { Get-Service -Name "ReportServer" } -Credential $cred
        if ($servicestatus.Status -eq "running")
        {
            $status.Text = $servicestatus.status
            $status.ForeColor = 'Green'
            $buttonStart.Enabled = $false
            $buttonStop.Enabled = $true
            $buttonRestart.Enabled = $true
        }
        else
        {
            $status.Text = $servicestatus.status
            $status.ForeColor = 'Red'
            $buttonStart.Enabled = $true
            $buttonStop.Enabled = $false
            $buttonRestart.Enabled = $false
        }
    }

    $buttonStart_Click={
        Invoke-Command -ComputerName $computer -ScriptBlock { Get-Service -Name "ReportServer" | Where-Object { $_.status -eq "stopped" }  | Start-Service } -Credential $cred
        $servicestatus = Invoke-Command -ComputerName $computer -ScriptBlock { Get-Service -Name "ReportServer" } -Credential $cred
        if ($servicestatus.Status -eq "running")
        {
            $status.Text = $servicestatus.status
            $status.ForeColor = 'Green'
            $buttonStart.Enabled = $false
            $buttonStop.Enabled = $true
            $buttonRestart.Enabled = $true
        }
        else
        {
            $status.Text = $servicestatus.status
            $status.ForeColor = 'Red'
            $buttonStart.Enabled = $true
            $buttonStop.Enabled = $false
            $buttonRestart.Enabled = $false
        }
    }

    $buttonStop_Click={
        Invoke-Command -ComputerName $computer -ScriptBlock { Get-Service -Name "ReportServer" | Where-Object { $_.status -eq "running" } | Stop-Service -Force } -Credential $cred
        $servicestatus = Invoke-Command -ComputerName $computer -ScriptBlock { Get-Service -Name "ReportServer" } -Credential $cred
        if ($servicestatus.Status -eq "running")
        {
            $status.Text = $servicestatus.status
            $status.ForeColor = 'Green'
            $buttonStart.Enabled = $false
            $buttonStop.Enabled = $true
            $buttonRestart.Enabled = $true
        }
        else
        {
            $status.Text = $servicestatus.status
            $status.ForeColor = 'Red'
            $buttonStart.Enabled = $true
            $buttonStop.Enabled = $false
            $buttonRestart.Enabled = $false
        }
    }

    $buttonRestart_Click={
        Invoke-Command -ComputerName $computer -ScriptBlock { Get-Service -Name "ReportServer" | Where-Object { $_.status -eq "running" } | Restart-Service -Force } -Credential $cred
        $servicestatus = Invoke-Command -ComputerName $computer -ScriptBlock { Get-Service -Name "ReportServer" } -Credential $cred
        if ($servicestatus.Status -eq "running")
        {
            $status.Text = $servicestatus.status
            $status.ForeColor = 'Green'
            $buttonStart.Enabled = $false
            $buttonStop.Enabled = $true
            $buttonRestart.Enabled = $true
        }
        else
        {
            $status.Text = $servicestatus.status
            $status.ForeColor = 'Red'
            $buttonStart.Enabled = $true
            $buttonStop.Enabled = $false
            $buttonRestart.Enabled = $false
        }
    }

	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formReportServerControls.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonRestart.remove_Click($buttonRestart_Click)
			$buttonStop.remove_Click($buttonStop_Click)
			$buttonStart.remove_Click($buttonStart_Click)
			$buttonRefresh.remove_Click($buttonRefresh_Click)
			$formReportServerControls.remove_Load($formReportServerControls_Load)
			$formReportServerControls.remove_Load($Form_StateCorrection_Load)
			$formReportServerControls.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formReportServerControls.SuspendLayout()
	$groupbox1.SuspendLayout()
	#
	# formReportServerControls
	#
	$formReportServerControls.Controls.Add($picturebox1)
	$formReportServerControls.Controls.Add($buttonRestart)
	$formReportServerControls.Controls.Add($buttonStop)
	$formReportServerControls.Controls.Add($buttonStart)
	$formReportServerControls.Controls.Add($groupbox1)
	$formReportServerControls.Controls.Add($buttonOK)
	$formReportServerControls.AcceptButton = $buttonOK
	$formReportServerControls.AutoScaleDimensions = '6, 13'
	$formReportServerControls.AutoScaleMode = 'Font'
	$formReportServerControls.ClientSize = '467, 266'
	$formReportServerControls.FormBorderStyle = 'FixedDialog'
	$formReportServerControls.MaximizeBox = $False
	$formReportServerControls.MinimizeBox = $False
	$formReportServerControls.Name = 'formReportServerControls'
	$formReportServerControls.StartPosition = 'CenterScreen'
	$formReportServerControls.Text = 'ReportServer Controls'
	$formReportServerControls.add_Load($formReportServerControls_Load)
	#
	# picturebox1
	#
	#region Binary Data
	$picturebox1.Image = [System.Convert]::FromBase64String('
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')
	#endregion
	$picturebox1.Location = '13, 204'
	$picturebox1.Name = 'picturebox1'
	$picturebox1.Size = '175, 36'
	$picturebox1.TabIndex = 5
	$picturebox1.TabStop = $False
	#
	# buttonRestart
	#
	$buttonRestart.Location = '345, 123'
	$buttonRestart.Name = 'buttonRestart'
	$buttonRestart.Size = '110, 50'
	$buttonRestart.TabIndex = 4
	$buttonRestart.Text = 'Restart'
	$buttonRestart.UseVisualStyleBackColor = $True
	$buttonRestart.add_Click($buttonRestart_Click)
	#
	# buttonStop
	#
	$buttonStop.Location = '185, 123'
	$buttonStop.Name = 'buttonStop'
	$buttonStop.Size = '110, 50'
	$buttonStop.TabIndex = 3
	$buttonStop.Text = 'Stop'
	$buttonStop.UseVisualStyleBackColor = $True
	$buttonStop.add_Click($buttonStop_Click)
	#
	# buttonStart
	#
	$buttonStart.Location = '13, 123'
	$buttonStart.Name = 'buttonStart'
	$buttonStart.Size = '110, 50'
	$buttonStart.TabIndex = 2
	$buttonStart.Text = 'Start'
	$buttonStart.UseVisualStyleBackColor = $True
	$buttonStart.add_Click($buttonStart_Click)
	#
	# groupbox1
	#
	$groupbox1.Controls.Add($status)
	$groupbox1.Controls.Add($labelStatus)
	$groupbox1.Controls.Add($buttonRefresh)
	$groupbox1.Location = '13, 13'
	$groupbox1.Name = 'groupbox1'
	$groupbox1.Size = '442, 71'
	$groupbox1.TabIndex = 1
	$groupbox1.TabStop = $False
	$groupbox1.Text = 'Service Status'
	#
	# status
	#
	$status.AutoSize = $True
	$status.Font = 'Microsoft Sans Serif, 12pt'
	$status.Location = '72, 26'
	$status.Name = 'status'
	$status.Size = '0, 20'
	$status.TabIndex = 2
	#
	# labelStatus
	#
	$labelStatus.AutoSize = $True
	$labelStatus.Font = 'Microsoft Sans Serif, 12pt'
	$labelStatus.Location = '6, 26'
	$labelStatus.Name = 'labelStatus'
	$labelStatus.Size = '60, 20'
	$labelStatus.TabIndex = 1
	$labelStatus.Text = 'Status:'
	#
	# buttonRefresh
	#
	$buttonRefresh.Location = '331, 20'
	$buttonRefresh.Name = 'buttonRefresh'
	$buttonRefresh.Size = '95, 34'
	$buttonRefresh.TabIndex = 0
	$buttonRefresh.Text = 'Refresh'
	$buttonRefresh.UseVisualStyleBackColor = $False
	$buttonRefresh.add_Click($buttonRefresh_Click)
	#
	# buttonOK
	#
	$buttonOK.Anchor = 'Bottom, Right'
	$buttonOK.DialogResult = 'OK'
	$buttonOK.Location = '380, 231'
	$buttonOK.Name = 'buttonOK'
	$buttonOK.Size = '75, 23'
	$buttonOK.TabIndex = 0
	$buttonOK.Text = '&OK'
	$buttonOK.UseVisualStyleBackColor = $True
	$groupbox1.ResumeLayout()
	$formReportServerControls.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formReportServerControls.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formReportServerControls.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formReportServerControls.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formReportServerControls.ShowDialog()

}

Function Get-Data($data)
{
	$output = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($data))
	return $output
}
    
# Variables
#################################

$encrpwd = '<password>'
$password = $password = Get-Data $encrpwd | ConvertTo-SecureString -AsPlainText -Force
$username = "domain\svc_ServiceMGMT"
$creds = New-Object -TypeName System.Management.Automation.PSCredential($username,$password)

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

Call-ReportServer_Controls_psf $creds

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit