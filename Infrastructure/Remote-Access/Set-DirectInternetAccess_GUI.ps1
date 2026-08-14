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
    Set-DirectInternetAccess_GUI.ps1

.SYNOPSIS
  Removes a specified account from ISAGROUP19 and adds account to Meraki security group.
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  07/10/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Removes a specified account from ISAGROUP19 and adds account to Meraki security group.

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
Hide-Console
Import-Module ActiveDirectory
$Script:ProductName = "Set-DirectInternetAccess" #Fill this in. Do not put the "TEAM_" prefix
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

function Set-IsaAccess
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $UFO_NUMBER
    )

    $str = $UFO_NUMBER + "str"
    $mgr = $UFO_NUMBER + "mgr"

    $accounts = @()
    $accounts += $str
    $accounts += $mgr

    $isa = (Get-ADGroupMember -Identity isagroup19).samaccountname
    $meraki = (Get-ADGroupMember -Identity "Meraki_Stores").samaccountname

    foreach($account in $accounts)
    {
        if($meraki -contains $account)
        {
            Remove-ADGroupMember -Identity "Meraki_Stores" -Members $account -Confirm:$false
            if($?)
            {
                Log_ToSplunk -Message "$account removed from Meraki_Stores"
                "$account removed from Meraki_Stores"
            }
            else 
            {
                Log_ToSplunk -Message "Unable to remove $account from Meraki_Stores"
                Write-Host "Unable to remove $account from Meraki_Stores" -ForegroundColor Red
            }
        }
        else 
        {
            Log_ToSplunk -Message "$account not found in Meraki_Stores"    
            Write-Host "$account not found in Meraki_Stores"
        }

        if($isa -contains $account)
        {
            Log_ToSplunk -Message "$account is already a member of ISAGROUP19"
            Write-Host "$account is already a member of ISAGROUP19"
        }
        else 
        {
            Add-ADGroupMember -Identity "ISAGROUP19" -Members $account -Confirm:$false
            if($?)
            {
                Log_ToSplunk -Message "$account added to ISAGROUP19"
                Write-Host "$account added to ISAGROUP19"
            }
            else 
            {
                Log_ToSplunk -Message "$account could not be added to ISAGROUP19"
                Write-Host "$account could not be added to ISAGROUP19" -ForegroundColor Red
            }
        }
    }
    #CHECKING!!!!
    $isacheck = (Get-ADGroupMember -Identity isagroup19).samaccountname
    $merakicheck = (Get-ADGroupMember -Identity "Meraki_Stores").samaccountname

    if(($merakicheck -notcontains $str) -and ($isacheck -contains $str)){$StoreStatus = $true}else{$StoreStatus -eq $false}
    if(($merakicheck -notcontains $mgr) -and ($isacheck -contains $mgr)){$ManagerStatus = $true}else{$ManagerStatus -eq $false}

    $output = New-Object -TypeName psobject -Property @{
        StoreStatus = $StoreStatus
        ManagerStatus = $ManagerStatus
    }
    return $output
}

function Set-DirectInternetAccess
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $UFO_NUMBER
    )

    $str = $UFO_NUMBER + "str"
    $mgr = $UFO_NUMBER + "mgr"

    $accounts = @()
    $accounts += $str
    $accounts += $mgr

    $isa = (Get-ADGroupMember -Identity isagroup19).samaccountname
    $meraki = (Get-ADGroupMember -Identity "Meraki_Stores").samaccountname

    foreach($account in $accounts)
    {
        if($isa -contains $account)
        {
            Remove-ADGroupMember -Identity "isagroup19" -Members $account -Confirm:$false
            if($?)
            {
                Log_ToSplunk -Message "$account removed from ISAGROUP19"
                Write-Host "$account removed from ISAGROUP19"
            }
            else 
            {
                Log_ToSplunk -Message "Unable to remove $account from ISAGROUP19"
                Write-Host "Unable to remove $account from ISAGROUP19" -ForegroundColor Red
            }
        }
        else 
        {
            Log_ToSplunk -Message "$account not found in ISAGROUP19"
            Write-Host "$account not found in ISAGROUP19"
        }

        if($meraki -contains $account)
        {
            Log_ToSplunk -Message "$account is already a member of Meraki_Stores"
            Write-Host "$account is already a member of Meraki_Stores"
        }
        else 
        {
            Add-ADGroupMember -Identity "Meraki_Stores" -Members $account -Confirm:$false
            if($?)
            {
                Log_ToSplunk -Message "$account succesfully added to Meraki_Stores" -Status "Success"
                Write-Host "$account succesfully added to Meraki_Stores"
            }
            else 
            {
                Log_ToSplunk -Message "Unable to add $account to Meraki_Stores" -Status "Fail"
                Write-host "Unable to add $account to Meraki_Stores" -ForegroundColor Red
            }
        }
    }

    #CHECKING!!!!
    $isacheck = (Get-ADGroupMember -Identity isagroup19).samaccountname
    $merakicheck = (Get-ADGroupMember -Identity "Meraki_Stores").samaccountname

    if(($merakicheck -contains $str) -and ($isacheck -notcontains $str)){$StoreStatus = $true}else{$StoreStatus -eq $false}
    if(($merakicheck -contains $mgr) -and ($isacheck -notcontains $mgr)){$ManagerStatus = $true}else{$ManagerStatus -eq $false}

    $output = New-Object -TypeName psobject -Property @{
        StoreStatus = $StoreStatus
        ManagerStatus = $ManagerStatus
    }
    return $output
}

function Get-UFO_NUMBER
{
    $flag = $false
    do
    {
        $store = Read-Host "Enter UFO_NUMBER"
        if($store.Length -gt 4)
        {
            Write-Host "You have entered an incorrect UFO_NUMBER, please try again." -ForegroundColor Red
        }
        else 
        {
            $flag = $true
        }
    }
    until($flag -eq $true)
    return $store
}

function Call-Set-DirectInternetAccess_psf {

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
	$formSetDirectInternetAcc = New-Object 'System.Windows.Forms.Form'
	$buttonSetIsaAccess = New-Object 'System.Windows.Forms.Button'
	$Statusbox = New-Object 'System.Windows.Forms.GroupBox'
	$ManagerStatus = New-Object 'System.Windows.Forms.Label'
	$StoreStatus = New-Object 'System.Windows.Forms.Label'
	$labelManagerAccount = New-Object 'System.Windows.Forms.Label'
	$labelStoreAccount = New-Object 'System.Windows.Forms.Label'
	$labelUFO_NUMBER = New-Object 'System.Windows.Forms.Label'
	$StoreInput = New-Object 'System.Windows.Forms.TextBox'
	$buttonSetDirectAccess = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$formSetDirectInternetAcc_Load={
		$buttonSetDirectAccess.Enabled = $false
		$buttonSetIsaAccess.Enabled = $false
	}
	
	$StoreInput_TextChanged={
		if ($StoreInput.Text -ne $null)
		{
			$buttonSetDirectAccess.Enabled = $true
			$buttonSetIsaAccess.Enabled = $true
		}
		if ($StoreInput.Text -eq "")
		{
			$buttonSetDirectAccess.Enabled = $false
			$buttonSetIsaAccess.Enabled = $false
		}
		$StoreStatus.Text = ""
		$ManagerStatus.Text = ""
	}
	
	$buttonSetDirectAccess_Click = {
		$store = $StoreInput.Text
		if ([RegEx]::IsMatch($Store, "\b\d{4}\b"))
		{
			#check to see if actual store...
			$str = $store + "str"
			$check = (Get-ADUser -Identity $str).samaccountname
			if ($check -ne $null)
			{
				$action = Set-DirectInternetAccess -UFO_NUMBER $store
				if ($action.StoreStatus -eq $true)
				{
					$StoreStatus.Text = "Store Account Added to Meraki_Stores"
					$StoreStatus.ForeColor = 'Green'
				}
				else
				{
					$StoreStatus.Text = "Something Went Wrong"
					$StoreStatus.ForeColor = 'Red'
				}
				if ($action.ManagerStatus -eq $true)
				{
					$ManagerStatus.Text = "Manager Account Added to Meraki_Stores"
					$ManagerStatus.ForeColor = 'Green'
				}
				else
				{
					$ManagerStatus.Text = "Something Went Wrong"
					$ManagerStatus.ForeColor = 'Red'
				}
			}
			else
			{
				$StoreStatus.Text = "Thats not a valid store"
				$StoreStatus.ForeColor = 'Red'
				$ManagerStatus.Text = "Thats not a valid store."
				$ManagerStatus.ForeColor = 'Red'
			}
		}
		else
		{
			$StoreStatus.Text = "Thats not a UFO_NUMBER."
			$StoreStatus.ForeColor = 'Red'
			$ManagerStatus.Text = "Thats not a UFO_NUMBER."
			$ManagerStatus.ForeColor = 'Red'
		}
	}
	
	$buttonSetIsaAccess_Click={
		$store = $StoreInput.Text
		if ([RegEx]::IsMatch($Store, "\b\d{4}\b"))
		{
			#check to see if actual store...
			$str = $store + "str"
			$check = (Get-ADUser -Identity $str).samaccountname
			if ($check -ne $null)
			{
				$action = Set-IsaAccess -UFO_NUMBER $store
				if ($action.StoreStatus -eq $true)
				{
					$StoreStatus.Text = "Store Account Added to ISAGROUP19"
					$StoreStatus.ForeColor = 'Green'
				}
				else
				{
					$StoreStatus.Text = "Something Went Wrong"
					$StoreStatus.ForeColor = 'Red'
				}
				if ($action.ManagerStatus -eq $true)
				{
					$ManagerStatus.Text = "Manager Account Added to ISAGROUP19"
					$ManagerStatus.ForeColor = 'Green'
				}
				else
				{
					$ManagerStatus.Text = "Something Went Wrong"
					$ManagerStatus.ForeColor = 'Red'
				}
			}
			else
			{
				$StoreStatus.Text = "Thats not a valid store"
				$StoreStatus.ForeColor = 'Red'
				$ManagerStatus.Text = "Thats not a valid store."
				$ManagerStatus.ForeColor = 'Red'
			}
		}
		else
		{
			$StoreStatus.Text = "Thats not a UFO_NUMBER."
			$StoreStatus.ForeColor = 'Red'
			$ManagerStatus.Text = "Thats not a UFO_NUMBER."
			$ManagerStatus.ForeColor = 'Red'
		}	
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formSetDirectInternetAcc.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonSetIsaAccess.remove_Click($buttonSetIsaAccess_Click)
			$StoreInput.remove_TextChanged($StoreInput_TextChanged)
			$buttonSetDirectAccess.remove_Click($buttonSetDirectAccess_Click)
			$formSetDirectInternetAcc.remove_Load($formSetDirectInternetAcc_Load)
			$formSetDirectInternetAcc.remove_Load($Form_StateCorrection_Load)
			$formSetDirectInternetAcc.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formSetDirectInternetAcc.SuspendLayout()
	$Statusbox.SuspendLayout()
	#
	# formSetDirectInternetAcc
	#
	$formSetDirectInternetAcc.Controls.Add($buttonSetIsaAccess)
	$formSetDirectInternetAcc.Controls.Add($Statusbox)
	$formSetDirectInternetAcc.Controls.Add($labelUFO_NUMBER)
	$formSetDirectInternetAcc.Controls.Add($StoreInput)
	$formSetDirectInternetAcc.Controls.Add($buttonSetDirectAccess)
	$formSetDirectInternetAcc.AutoScaleDimensions = '8, 19'
	$formSetDirectInternetAcc.AutoScaleMode = 'Font'
	$formSetDirectInternetAcc.BackColor = 'Control'
	$formSetDirectInternetAcc.ClientSize = '320, 350'
	$formSetDirectInternetAcc.Font = 'Calibri, 12pt'
	$formSetDirectInternetAcc.FormBorderStyle = 'FixedSingle'
	$formSetDirectInternetAcc.Margin = '3, 4, 3, 4'
	$formSetDirectInternetAcc.MaximizeBox = $False
	$formSetDirectInternetAcc.Name = 'formSetDirectInternetAcc'
	$formSetDirectInternetAcc.Text = 'Set-DirectInternetAccess'
	$formSetDirectInternetAcc.add_Load($formSetDirectInternetAcc_Load)
	#
	# buttonSetIsaAccess
	#
	$buttonSetIsaAccess.Location = '92, 133'
	$buttonSetIsaAccess.Margin = '3, 4, 3, 4'
	$buttonSetIsaAccess.Name = 'buttonSetIsaAccess'
	$buttonSetIsaAccess.Size = '131, 34'
	$buttonSetIsaAccess.TabIndex = 4
	$buttonSetIsaAccess.Text = 'Set-IsaAccess'
	$buttonSetIsaAccess.UseVisualStyleBackColor = $True
	$buttonSetIsaAccess.add_Click($buttonSetIsaAccess_Click)
	#
	# Statusbox
	#
	$Statusbox.Controls.Add($ManagerStatus)
	$Statusbox.Controls.Add($StoreStatus)
	$Statusbox.Controls.Add($labelManagerAccount)
	$Statusbox.Controls.Add($labelStoreAccount)
	$Statusbox.Location = '11, 192'
	$Statusbox.Margin = '3, 4, 3, 4'
	$Statusbox.Name = 'Statusbox'
	$Statusbox.Padding = '3, 4, 3, 4'
	$Statusbox.Size = '297, 146'
	$Statusbox.TabIndex = 3
	$Statusbox.TabStop = $False
	$Statusbox.Text = 'Status'
	#
	# ManagerStatus
	#
	$ManagerStatus.AutoSize = $True
	$ManagerStatus.Location = '7, 105'
	$ManagerStatus.Name = 'ManagerStatus'
	$ManagerStatus.Size = '0, 19'
	$ManagerStatus.TabIndex = 3
	#
	# StoreStatus
	#
	$StoreStatus.AutoSize = $True
	$StoreStatus.Location = '7, 45'
	$StoreStatus.Name = 'StoreStatus'
	$StoreStatus.Size = '0, 19'
	$StoreStatus.TabIndex = 2
	#
	# labelManagerAccount
	#
	$labelManagerAccount.AutoSize = $True
	$labelManagerAccount.Location = '7, 83'
	$labelManagerAccount.Name = 'labelManagerAccount'
	$labelManagerAccount.Size = '127, 19'
	$labelManagerAccount.TabIndex = 1
	$labelManagerAccount.Text = 'Manager Account:'
	#
	# labelStoreAccount
	#
	$labelStoreAccount.AutoSize = $True
	$labelStoreAccount.Location = '7, 23'
	$labelStoreAccount.Name = 'labelStoreAccount'
	$labelStoreAccount.Size = '102, 19'
	$labelStoreAccount.TabIndex = 0
	$labelStoreAccount.Text = 'Store Account:'
	#
	# labelUFO_NUMBER
	#
	$labelUFO_NUMBER.AutoSize = $True
	$labelUFO_NUMBER.BackColor = 'Transparent'
	$labelUFO_NUMBER.Location = '107, 32'
	$labelUFO_NUMBER.Name = 'labelUFO_NUMBER'
	$labelUFO_NUMBER.Size = '97, 19'
	$labelUFO_NUMBER.TabIndex = 2
	$labelUFO_NUMBER.Text = 'UFO_NUMBER'
	#
	# StoreInput
	#
	$StoreInput.Location = '92, 58'
	$StoreInput.Margin = '3, 4, 3, 4'
	$StoreInput.MaxLength = 4
	$StoreInput.Name = 'StoreInput'
	$StoreInput.Size = '132, 27'
	$StoreInput.TabIndex = 1
	$StoreInput.add_TextChanged($StoreInput_TextChanged)
	#
	# buttonSetDirectAccess
	#
	$buttonSetDirectAccess.Location = '92, 91'
	$buttonSetDirectAccess.Margin = '3, 4, 3, 4'
	$buttonSetDirectAccess.Name = 'buttonSetDirectAccess'
	$buttonSetDirectAccess.Size = '131, 34'
	$buttonSetDirectAccess.TabIndex = 0
	$buttonSetDirectAccess.Text = 'Set-DirectAccess'
	$buttonSetDirectAccess.UseVisualStyleBackColor = $True
	$buttonSetDirectAccess.add_Click($buttonSetDirectAccess_Click)
	$Statusbox.ResumeLayout()
	$formSetDirectInternetAcc.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formSetDirectInternetAcc.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formSetDirectInternetAcc.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formSetDirectInternetAcc.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formSetDirectInternetAcc.ShowDialog()

}

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

Call-Set-DirectInternetAccess_psf

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit