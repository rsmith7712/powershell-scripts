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
    Toggle-DM_Maintenance.ps1

.DESCRIPTION
    Toggles the DM Maintenance page on/off by removing/adding servers to the active DM pool via the A10 REST API.

.FUNCTIONALITY
    Toggles the DM Maintenance page on/off by removing/adding servers to the active DM pool via the A10 REST API.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# ----------------------------------------------------------------------------------------------
# Initializations

$ErrorActionPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ----------------------------------------------------------------------------------------------
# Logging

# below to be replaced by splunk logger
<#
$stamp = get-date -Format yyyy.MM.dd-HH.mm.ss
$Script:Logfile = "C:\temp\FILENAME_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, OU, License Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}
#>

# ----------------------------------------------------------------------------------------------
# Functions

# function to force REST requests to ignore self signed SSL certs. Function found: https://www.datacore.com/RESTSupport-Webhelp/using_windows_powershell_as_a_rest_client.htm
function Ignore-SelfSignedCerts
{
    try
    {

        #Write-Host "Adding TrustAllCertsPolicy type." -ForegroundColor White
        Add-Type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy
        {
             public bool CheckValidationResult(
             ServicePoint srvPoint, X509Certificate certificate,
             WebRequest request, int certificateProblem)
             {
                 return true;
            }
        }
"@

        #Write-Host "TrustAllCertsPolicy type added." -ForegroundColor White
      }
    catch
    {
        #Write-Host $_ -ForegroundColor "Yellow"
    }

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
# RUN FUNCTION IMMEDIATELY
Ignore-SelfSignedCerts

# function creates a POST request to axAPI to retrieve the authkey variable that will be placed in more variables going forward
function DM_Auth
{
    $credential = Get-Credential -Message "Please enter A10 Networks administrator credentials."
    $user = $credential.username
    $pass = $credential.GetNetworkCredential().password

    $uri = 'https://0.0.0.0/axapi/v3/auth'
    $headers = @{}
    $headers.add('Content-Type', 'application/json')
    $body = @{
        credentials = @{
            username = $user
            password = $pass
        }
    }
    $body = $body | ConvertTo-Json

    $rawdata = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    $rawdata = $rawdata | ConvertFrom-Json

    if ($rawdata.authresponse -eq $null)
    {
        #Write-Host "There was an error, printing response from webpage."
        #Write-Host $rawdata
        exit
    }

    $dmauth = $rawdata.authresponse.signature
    $dmauth = "A10 " + $dmauth

   return $dmauth
}

# This function uses a GET request to get a list of servers and their statuses.  Returns $true or $false depending on server status.
function get_status_admin
{
    $uri = "https://0.0.0.0/axapi/v3/slb/service-group/dm_example.com_80_tcp/member-list"
    $headers = @{}
    $headers.add('Content-Type', 'application/json')
    $headers.add('Authorization', $script:dmauthkey)

    $rawdata = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    $rawdata = $rawdata | ConvertFrom-Json
    #$rawdata.'member-list'
    $enabled = @()
    $disabled = @()
    foreach ($server in $rawdata.'member-list')
    {
        if ($server.'member-state' -eq "enable")
        {
            $enabled += $server.name
            $enabledhash.Add($server.name, 'enable')
        }
        elseif ($server.'member-state' -eq "disable")
        {
            $disabled += $server.name
            $disabledhash.Add($server.name, 'disable')
        }
    }
    if(($enabled.count -gt 0) -and ($disabled.count -eq 0))
    {
        #write-host "Admin maintenance page is disabled"
        return $false
    }
    elseif(($disabled.count -gt 0) -and ($enabled.count -eq 0))
    {
        #Write-Host "Admin maintenance page is enabled"
        return $true
    }
    else 
    {
        return $null
    }
}

# this function is used to remove the servers from the pool which will turn on the maintenance page
# First gets list of servers and captures their UUIDs and stores them in an array
# then uses UUIDs to build new URL and sends POST request to that URL to disable the server
function enable_maintenance_admin
{
    #first, get list of UUIDs of the servers we will be pulling out of the pool
    $uri = "https://0.0.0.0/axapi/v3/slb/service-group/dm_example.com_80_tcp/member-list"
    $headers = @{}
    $headers.add('Content-Type', 'application/json')
    $headers.add('Authorization', $script:dmauthkey)
    
    $rawdata = Invoke-RestMethod -uri $uri -headers $headers -Method Get
    $rawdata = $rawdata | ConvertFrom-Json
    $UUIDs = @()
    foreach($server in $rawdata.'member-list')
    {
        $UUIDs += $server.uuid
    }
    
    $body = @{
        server = @{
            action = disable
        }
    }
    $body = $body | ConvertTo-Json

    $uuid_url = "https://0.0.0.0/axapi/v3/uuid/"

    foreach($uuid in $UUIDs)
    {
        Invoke-RestMethod -Uri ($uuid_url + $uuid) -Method Post -Body $body -Headers $headers
        if($? -eq $false)
        {
            return $false
            break
        }
    }
}

# this function is used to put servers back into the pool, disabling the maintenance page
# First gets list of servers and captures their UUIDs and stores them in an array
# then uses UUIDs to build new URL and sends POST request to that URL to enable the server
function disable_maintenance_admin
{
    #first, get list of UUIDs of the servers we will be pulling out of the pool
    $uri = "https://0.0.0.0/axapi/v3/slb/service-group/dm_example.com_80_tcp/member-list"
    $headers = @{}
    $headers.add('Content-Type', 'application/json')
    $headers.add('Authorization', $script:dmauthkey)
    
    $rawdata = Invoke-RestMethod -uri $uri -headers $headers -Method Get
    $rawdata = $rawdata | ConvertFrom-Json
    $UUIDs = @()
    foreach($server in $rawdata.'member-list')
    {
        $UUIDs += $server.uuid
    }
    
    $body = @{
        server = @{
            action = enable
        }
    }
    $body = $body | ConvertTo-Json

    $uuid_url = "https://0.0.0.0/axapi/v3/uuid/"

    foreach($uuid in $UUIDs)
    {
        Invoke-RestMethod -Uri ($uuid_url + $uuid) -Method Post -Body $body -Headers $headers
        if($? -eq $false)
        {
            return $false
            break
        }
    }
}

# This function uses a GET request to get a list of servers and their statuses.  Returns $true or $false depending on server status.
function get_status_public
{
    $uri = "https://0.0.0.0/axapi/v3/slb/service-group/dm_partners_80_tcp/member-list"
    $headers = @{}
    $headers.add('Content-Type', 'application/json')
    $headers.add('Authorization', $script:dmauthkey)

    $rawdata = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    $rawdata = $rawdata | ConvertFrom-Json
    #$rawdata.'member-list'
    $enabled = @()
    $disabled = @()
    foreach ($server in $rawdata.'member-list')
    {
        if ($server.'member-state' -eq "enable")
        {
            $enabled += $server.name
            $enabledhash.Add($server.name, 'enable')
        }
        elseif ($server.'member-state' -eq "disable")
        {
            $disabled += $server.name
            $disabledhash.Add($server.name, 'disable')
        }
    }
    if(($enabled.count -gt 0) -and ($disabled.count -eq 0))
    {
        ##write-host "Public maintenance page is disabled"
        return $false
    }
    elseif(($disabled.count -gt 0) -and ($enabled.count -eq 0))
    {
        ##Write-Host "Public maintenance page is enabled"
        return $true
    }
    else 
    {
        return $null
    }
}

# this function is used to remove the servers from the pool which will turn on the maintenance page
# First gets list of servers and captures their UUIDs and stores them in an array
# then uses UUIDs to build new URL and sends POST request to that URL to disable the server
function enable_maintenance_public
{
    #first, get list of UUIDs of the servers we will be pulling out of the pool
    $uri = "https://0.0.0.0/axapi/v3/slb/service-group/dm_partners_80_tcp/member-list"
    $headers = @{}
    $headers.add('Content-Type', 'application/json')
    $headers.add('Authorization', $script:dmauthkey)
    
    $rawdata = Invoke-RestMethod -uri $uri -headers $headers -Method Get
    $rawdata = $rawdata | ConvertFrom-Json
    $UUIDs = @()
    foreach($server in $rawdata.'member-list')
    {
        $UUIDs += $server.uuid
    }
    
    $body = @{
        server = @{
            action = disable
        }
    }
    $body = $body | ConvertTo-Json

    $uuid_url = "https://0.0.0.0/axapi/v3/uuid/"

    foreach($uuid in $UUIDs)
    {
        Invoke-RestMethod -Uri ($uuid_url + $uuid) -Method Post -Body $body -Headers $headers
        if($? -eq $false)
        {
            return $false
            break
        }
    }
}

# this function is used to put servers back into the pool, disabling the maintenance page
# First gets list of servers and captures their UUIDs and stores them in an array
# then uses UUIDs to build new URL and sends POST request to that URL to enable the server
function disable_maintenance_public
{
    #first, get list of UUIDs of the servers we will be pulling out of the pool
    $uri = "https://0.0.0.0/axapi/v3/slb/service-group/dm_partners_80_tcp/member-list"
    $headers = @{}
    $headers.add('Content-Type', 'application/json')
    $headers.add('Authorization', $script:dmauthkey)
    
    $rawdata = Invoke-RestMethod -uri $uri -headers $headers -Method Get
    $rawdata = $rawdata | ConvertFrom-Json
    $UUIDs = @()
    foreach($server in $rawdata.'member-list')
    {
        $UUIDs += $server.uuid
    }
    
    $body = @{
        server = @{
            action = enable
        }
    }
    $body = $body | ConvertTo-Json

    $uuid_url = "https://0.0.0.0/axapi/v3/uuid/"

    foreach($uuid in $UUIDs)
    {
        Invoke-RestMethod -Uri ($uuid_url + $uuid) -Method Post -Body $body -Headers $headers
        if($? -eq $false)
        {
            return $false
            break
        }
    }
}

# this function removes the admin session to the A10 API. 
function logoff_api
{
    $uri = "https://0.0.0.0/axapi/v3/logoff"
    $headers = @{}
    $headers.add('Content-Type', 'application/json')
    $headers.add('Authorization', $script:dmauthkey)

    Invoke-RestMethod -Uri $uri -Method Get -Headers $headers | Out-Null
    
}

# GUI function, built using SAPIEN Powershell Studio
function Call-Toggle-DM_Maintenance_psf {

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
	$formToggleDMMaintenanceP = New-Object 'System.Windows.Forms.Form'
	$buttonRefresh = New-Object 'System.Windows.Forms.Button'
	$labelStatusPublic = New-Object 'System.Windows.Forms.Label'
	$buttonDisablePublic = New-Object 'System.Windows.Forms.Button'
	$buttonEnablePublic = New-Object 'System.Windows.Forms.Button'
	$labelPublicControls = New-Object 'System.Windows.Forms.Label'
	$labelAdminControls = New-Object 'System.Windows.Forms.Label'
	$labelStatusAdmin = New-Object 'System.Windows.Forms.Label'
	$buttonDisableAdmin = New-Object 'System.Windows.Forms.Button'
	$buttonEnableAdmin = New-Object 'System.Windows.Forms.Button'
	$buttonQuit = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	$formToggleDMMaintenanceP_Load = {
		#TODO: Initialize Form Controls here
		if ($status_admin -eq $false)
		{
			$labelStatusAdmin.Text = "Admin maintenance page is currently disabled"
		}
		elseif ($status_admin -eq $true)
		{
			$labelStatusAdmin.Text = "Admin maintenance page is currently enabled"
		}
		elseif ($status_admin -eq $null)
		{
			$labelStatusAdmin.Text = "Admin maintenance page is currently in unexpected state `nPlease click 'Refresh' to run check again or contact administrator if problem persists."
		}
		
		if ($status_public -eq $false)
		{
			$labelStatusPublic.Text = "Public maintenance page is currently disabled"
		}
		elseif ($status_public -eq $true)
		{
			$labelStatusPublic.Text = "Public maintenance page is currently enabled"
		}
		elseif ($status_public -eq $null)
		{
			$labelStatusAdmin.Text = "Public maintenance page is currently in unexpected state `nPlease click 'Refresh' to run check again or contact administrator if problem persists."
		}
		
		$buttonEnableAdmin.Enabled = $false
		if ($status_admin -eq $false)
		{
			$buttonEnableAdmin.Enabled = $true
		}
		
		$buttonDisableAdmin.Enabled = $false
		if ($status_admin -eq $true)
		{
			$buttonDisableAdmin.Enabled = $true
		}
		
		$buttonEnablePublic.Enabled = $false
		if ($status_public -eq $false)
		{
			$buttonEnablePublic.Enabled = $true
		}
		
		$buttonDisablePublic.Enabled = $false
		if ($status_public -eq $true)
		{
			$buttonDisablePublic.Enabled = $true
		}
	}
	
	$buttonQuit_Click={
		#TODO: Place custom script here
		logoff_api
	}
	
	$buttonEnableAdmin_Click={
        #TODO: Place custom script here
        $messageenableadmin = "Are you sure you want `nto enable the maintenance page?"
        if ((Call-Confirm_psf $messageenableadmin) -eq "Yes")
        {
            $actionstatus = enable_maintenance_admin
            if($actionstatus -eq $False)
            {
                $message = "An error has occured, unable to enable maintenance page. `nIf problem persists, please contact an administrator"
                Call-Error_psf $message
            }
            get_status_admin
            $formToggleDMMaintenanceP.Refresh()
        }
	}
	
	$buttonDisableAdmin_Click={
        #TODO: Place custom script here
        $messagedisableadmin = "Are you sure you want `nto disable the maintenance page?"
        if ((Call-Confirm_psf $messagedisableadmin) -eq "Yes")
        {
            $actionstatus = disable_maintenance_admin
            if($actionstatus -eq $False)
            {
                $message = "An error has occured, unable to disable maintenance page. `nIf problem persists, please contact an administrator"
                Call-Error_psf $message
            }
            get_status_admin
            $formToggleDMMaintenanceP.Refresh()
        }
	}
	
	$buttonEnablePublic_Click={
        #TODO: Place custom script here
        $messageenablepublic = "Are you sure you want `nto enable the maintenance page?"
        if ((Call-Confirm_psf $messageenablepublic) -eq "Yes")
        {
            $actionstatus = enable_maintenance_public
            if($actionstatus -eq $False)
            {
                $message = "An error has occured, unable to enable maintenance page. `nIf problem persists, please contact an administrator"
                Call-Error_psf $message
            }
            get_status_public
            $formToggleDMMaintenanceP.Refresh()
        }
	}
	
	$buttonDisablePublic_Click={
        #TODO: Place custom script here
        $messagedisablepublic = "Are you sure you want `nto disable the maintenance page?"
        if ((Call-Confirm_psf $messagedisablepublic) -eq "Yes")
        {
            $actionstatus = disable_maintenance_public
            if($actionstatus -eq $False)
            {
                $message = "An error has occured, unable to disable maintenance page. `nIf problem persists, please contact an administrator"
                Call-Error_psf $message
            }
            get_status_public
            $formToggleDMMaintenanceP.Refresh()
        }
	}
	
	$buttonRefresh_Click={
		#TODO: Place custom script here
		$formToggleDMMaintenanceP.Refresh()
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formToggleDMMaintenanceP.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonRefresh.remove_Click($buttonRefresh_Click)
			$buttonDisablePublic.remove_Click($buttonDisablePublic_Click)
			$buttonEnablePublic.remove_Click($buttonEnablePublic_Click)
			$buttonDisableAdmin.remove_Click($buttonDisableAdmin_Click)
			$buttonEnableAdmin.remove_Click($buttonEnableAdmin_Click)
			$buttonQuit.remove_Click($buttonQuit_Click)
			$formToggleDMMaintenanceP.remove_Load($formToggleDMMaintenanceP_Load)
			$formToggleDMMaintenanceP.remove_Load($Form_StateCorrection_Load)
			$formToggleDMMaintenanceP.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formToggleDMMaintenanceP.SuspendLayout()
	#
	# formToggleDMMaintenanceP
	#
	$formToggleDMMaintenanceP.Controls.Add($buttonRefresh)
	$formToggleDMMaintenanceP.Controls.Add($labelStatusPublic)
	$formToggleDMMaintenanceP.Controls.Add($buttonDisablePublic)
	$formToggleDMMaintenanceP.Controls.Add($buttonEnablePublic)
	$formToggleDMMaintenanceP.Controls.Add($labelPublicControls)
	$formToggleDMMaintenanceP.Controls.Add($labelAdminControls)
	$formToggleDMMaintenanceP.Controls.Add($labelStatusAdmin)
	$formToggleDMMaintenanceP.Controls.Add($buttonDisableAdmin)
	$formToggleDMMaintenanceP.Controls.Add($buttonEnableAdmin)
	$formToggleDMMaintenanceP.Controls.Add($buttonQuit)
	$formToggleDMMaintenanceP.AutoScaleDimensions = '6, 13'
	$formToggleDMMaintenanceP.AutoScaleMode = 'Font'
	$formToggleDMMaintenanceP.ClientSize = '377, 271'
	$formToggleDMMaintenanceP.ControlBox = $False
	$formToggleDMMaintenanceP.FormBorderStyle = 'FixedDialog'
	$formToggleDMMaintenanceP.MaximizeBox = $False
	$formToggleDMMaintenanceP.MinimizeBox = $False
	$formToggleDMMaintenanceP.Name = 'formToggleDMMaintenanceP'
	$formToggleDMMaintenanceP.StartPosition = 'CenterScreen'
	$formToggleDMMaintenanceP.Text = 'Toggle DM Maintenance Page'
	$formToggleDMMaintenanceP.add_Load($formToggleDMMaintenanceP_Load)
	#
	# buttonRefresh
	#
	$buttonRefresh.Location = '289, 13'
	$buttonRefresh.Name = 'buttonRefresh'
	$buttonRefresh.Size = '75, 23'
	$buttonRefresh.TabIndex = 9
	$buttonRefresh.Text = 'Refresh - All'
	$buttonRefresh.UseVisualStyleBackColor = $True
	$buttonRefresh.add_Click($buttonRefresh_Click)
	#
	# labelStatusPublic
	#
	$labelStatusPublic.AutoSize = $True
	$labelStatusPublic.Location = '127, 183'
	$labelStatusPublic.Name = 'labelStatusPublic'
	$labelStatusPublic.Size = '64, 13'
	$labelStatusPublic.TabIndex = 8
	$labelStatusPublic.Text = 'statusPublic'
	#
	# buttonDisablePublic
	#
	$buttonDisablePublic.Location = '12, 212'
	$buttonDisablePublic.Name = 'buttonDisablePublic'
	$buttonDisablePublic.Size = '75, 23'
	$buttonDisablePublic.TabIndex = 7
	$buttonDisablePublic.Text = 'Disable'
	$buttonDisablePublic.UseVisualStyleBackColor = $True
	$buttonDisablePublic.add_Click($buttonDisablePublic_Click)
	#
	# buttonEnablePublic
	#
	$buttonEnablePublic.Location = '13, 183'
	$buttonEnablePublic.Name = 'buttonEnablePublic'
	$buttonEnablePublic.Size = '75, 23'
	$buttonEnablePublic.TabIndex = 6
	$buttonEnablePublic.Text = 'Enable'
	$buttonEnablePublic.UseVisualStyleBackColor = $True
	$buttonEnablePublic.add_Click($buttonEnablePublic_Click)
	#
	# labelPublicControls
	#
	$labelPublicControls.AutoSize = $True
	$labelPublicControls.Location = '13, 141'
	$labelPublicControls.Name = 'labelPublicControls'
	$labelPublicControls.Size = '77, 13'
	$labelPublicControls.TabIndex = 5
	$labelPublicControls.Text = 'Public Controls'
	#
	# labelAdminControls
	#
	$labelAdminControls.AutoSize = $True
	$labelAdminControls.Location = '13, 13'
	$labelAdminControls.Name = 'labelAdminControls'
	$labelAdminControls.Size = '77, 13'
	$labelAdminControls.TabIndex = 4
	$labelAdminControls.Text = 'Admin Controls'
	#
	# labelStatusAdmin
	#
	$labelStatusAdmin.AutoSize = $True
	$labelStatusAdmin.Location = '127, 51'
	$labelStatusAdmin.Name = 'labelStatusAdmin'
	$labelStatusAdmin.Size = '64, 13'
	$labelStatusAdmin.TabIndex = 3
	$labelStatusAdmin.Text = 'statusAdmin'
	#
	# buttonDisableAdmin
	#
	$buttonDisableAdmin.Location = '12, 80'
	$buttonDisableAdmin.Name = 'buttonDisableAdmin'
	$buttonDisableAdmin.Size = '75, 23'
	$buttonDisableAdmin.TabIndex = 2
	$buttonDisableAdmin.Text = 'Disable'
	$buttonDisableAdmin.UseVisualStyleBackColor = $True
	$buttonDisableAdmin.add_Click($buttonDisableAdmin_Click)
	#
	# buttonEnableAdmin
	#
	$buttonEnableAdmin.Location = '12, 51'
	$buttonEnableAdmin.Name = 'buttonEnableAdmin'
	$buttonEnableAdmin.Size = '75, 23'
	$buttonEnableAdmin.TabIndex = 1
	$buttonEnableAdmin.Text = 'Enable'
	$buttonEnableAdmin.UseVisualStyleBackColor = $True
	$buttonEnableAdmin.add_Click($buttonEnableAdmin_Click)
	#
	# buttonQuit
	#
	$buttonQuit.Anchor = 'Bottom, Right'
	$buttonQuit.DialogResult = 'Cancel'
	$buttonQuit.Location = '290, 236'
	$buttonQuit.Name = 'buttonQuit'
	$buttonQuit.Size = '75, 23'
	$buttonQuit.TabIndex = 0
	$buttonQuit.Text = '&Quit'
	$buttonQuit.UseVisualStyleBackColor = $True
	$buttonQuit.add_Click($buttonQuit_Click)
	$formToggleDMMaintenanceP.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formToggleDMMaintenanceP.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formToggleDMMaintenanceP.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formToggleDMMaintenanceP.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formToggleDMMaintenanceP.ShowDialog()

}

# Confirmation pop-up window. Built using Sapien Powershell Studio.
function Call-Confirm_psf($message) {

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
	$formConfirm = New-Object 'System.Windows.Forms.Form'
	$buttonYes = New-Object 'System.Windows.Forms.Button'
	$buttonNo = New-Object 'System.Windows.Forms.Button'
	$labelAreYouSure = New-Object 'System.Windows.Forms.Label'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$formConfirm_Load={
		#TODO: Initialize Form Controls here
		
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formConfirm.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$formConfirm.remove_Load($formConfirm_Load)
			$formConfirm.remove_Load($Form_StateCorrection_Load)
			$formConfirm.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formConfirm.SuspendLayout()
	#
	# formConfirm
	#
	$formConfirm.Controls.Add($buttonYes)
	$formConfirm.Controls.Add($buttonNo)
	$formConfirm.Controls.Add($labelAreYouSure)
	$formConfirm.AutoScaleDimensions = '6, 13'
	$formConfirm.AutoScaleMode = 'Font'
	$formConfirm.ClientSize = '265, 106'
	$formConfirm.FormBorderStyle = 'FixedDialog'
	$formConfirm.MaximizeBox = $False
	$formConfirm.MinimizeBox = $False
	$formConfirm.Name = 'formConfirm'
	$formConfirm.StartPosition = 'CenterScreen'
	$formConfirm.Text = 'Confirm'
	$formConfirm.add_Load($formConfirm_Load)
	#
	# buttonYes
	#
	$buttonYes.DialogResult = 'Yes'
	$buttonYes.Location = '97, 71'
	$buttonYes.Name = 'buttonYes'
	$buttonYes.Size = '75, 23'
	$buttonYes.TabIndex = 2
	$buttonYes.Text = 'Yes'
	$buttonYes.UseVisualStyleBackColor = $True
	#
	# buttonNo
	#
	$buttonNo.DialogResult = 'No'
	$buttonNo.Location = '178, 71'
	$buttonNo.Name = 'buttonNo'
	$buttonNo.Size = '75, 23'
	$buttonNo.TabIndex = 1
	$buttonNo.Text = 'No'
	$buttonNo.UseVisualStyleBackColor = $True
	#
	# labelAreYouSure
	#
	$labelAreYouSure.AutoSize = $True
	$labelAreYouSure.Location = '13, 13'
	$labelAreYouSure.Name = 'labelAreYouSure'
	$labelAreYouSure.Size = '72, 13'
	$labelAreYouSure.TabIndex = 0
	$labelAreYouSure.Text = $message
	$formConfirm.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formConfirm.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formConfirm.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formConfirm.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formConfirm.ShowDialog()

}

#error pop-up dialogue
function Call-Error_psf($message) {

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
	$formERROR = New-Object 'System.Windows.Forms.Form'
	$ErrorMessage = New-Object 'System.Windows.Forms.Label'
	$buttonOK = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$formERROR_Load={
		#TODO: Initialize Form Controls here
		$ErrorMessage.Text = $message
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formERROR.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$formERROR.remove_Load($formERROR_Load)
			$formERROR.remove_Load($Form_StateCorrection_Load)
			$formERROR.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formERROR.SuspendLayout()
	#
	# formERROR
	#
	$formERROR.Controls.Add($ErrorMessage)
	$formERROR.Controls.Add($buttonOK)
	$formERROR.AcceptButton = $buttonOK
	$formERROR.AutoScaleDimensions = '6, 13'
	$formERROR.AutoScaleMode = 'Font'
	$formERROR.ClientSize = '314, 121'
	$formERROR.FormBorderStyle = 'FixedDialog'
	$formERROR.MaximizeBox = $False
	$formERROR.MinimizeBox = $False
	$formERROR.Name = 'formERROR'
	$formERROR.StartPosition = 'CenterScreen'
	$formERROR.Text = 'ERROR'
	$formERROR.add_Load($formERROR_Load)
	#
	# ErrorMessage
	#
	$ErrorMessage.AutoSize = $True
	$ErrorMessage.Location = '13, 13'
	$ErrorMessage.Name = 'ErrorMessage'
	$ErrorMessage.Size = '0, 13'
	$ErrorMessage.TabIndex = 1
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
	$formERROR.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formERROR.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formERROR.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formERROR.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formERROR.ShowDialog()

}

# ----------------------------------------------------------------------------------------------
# Variables

$script:dmauthkey = DM_Auth
$status_admin = get_status_admin
$status_public = get_status_public

# ----------------------------------------------------------------------------------------------
# Script
Call-Toggle-DM_Maintenance_psf | Out-Null

# ALWAYS RUN LOGOFF IF AN AUTH TOKEN HAS BEEN ASSIGNED
logoff_api