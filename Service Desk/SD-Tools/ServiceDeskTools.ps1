<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 04/18/2018
    Organization: Domain, Inc.
    Filename: ServiceDeskTools.ps1
    =========================================================
    .DESCRIPTION
        A collection of scripts/functions/tools used by the Service Desk wrapped in a GUI interface

    .VERSION INFO
		v1.4.1 - 6/29/2018
		- Adds Themes
		- Buttons sorted into categories
		- Added useful links
		
	.VERSION HISTORY
        v1 - Initial script build
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
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 4) | Out-Null
}

function Hide-Console
{
	$ConsoleHandle = [Native.WinAPI]::GetConsoleWindow()
	[Native.WinAPI]::ShowWindow($ConsoleHandle, 0) | Out-Null
	$consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0) | Out-Null
}
###############################################################

# ----------------------------------------------------------------------------------------------
# Initializations

Hide-Console
Import-Module -Name ActiveDirectory
$ErrorActionPreference = "SilentlyContinue"
$Script:ProductName = "ServiceDeskTools" #Fill this in. Do not put the "TEAM_" prefix
$version = "1.4.3"
$UpdateDate = "10/09/2018"
$Author = "user22"

# ----------------------------------------------------------------------------------------------
# Logging

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

# ----------------------------------------------------------------------------------------------
# Functions

function Test-Port
{
        
    <#
        .Synopsis 
            Test a host to see if the specified port is open.
            
        .Description
            Test a host to see if the specified port is open.
                        
        .Parameter TCPPort 
            Port to test (Default 135.)
            
        .Parameter Timeout 
            How long to wait (in milliseconds) for the TCP connection (Default 3000.)
            
        .Parameter ComputerName 
            Computer to test the port against (Default in localhost.)
            
        .Example
            Test-Port -tcp 3389
            Description
            -----------
            Returns $True if the localhost is listening on 3389
            
        .Example
            Test-Port -tcp 3389 -ComputerName MyServer1
            Description
            -----------
            Returns $True if MyServer1 is listening on 3389
                    
        .OUTPUTS
            System.Boolean
            
        .INPUTS
            System.String
            
        .Link
            Test-Host
            Wait-Port
            
        .Notes
            NAME:      Test-Port
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter()]
        [int]$TCPport = 135,
        [Parameter()]
        [int]$TimeOut = 3000,
        [Alias("dnsHostName")]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [String]$ComputerName = $env:COMPUTERNAME
    )
    Begin 
    {
        Write-Verbose " [Test-Port] :: Start Script"
        Write-Verbose " [Test-Port] :: Setting Error state = 0"
    }
    
    Process 
    {
    
        Write-Verbose " [Test-Port] :: Creating [system.Net.Sockets.TcpClient] instance"
        $tcpclient = New-Object system.Net.Sockets.TcpClient
        
        Write-Verbose " [Test-Port] :: Calling BeginConnect($ComputerName,$TCPport,$null,$null)"
        try
        {
            $iar = $tcpclient.BeginConnect($ComputerName,$TCPport,$null,$null)
            Write-Verbose " [Test-Port] :: Waiting for timeout [$timeout]"
            $wait = $iar.AsyncWaitHandle.WaitOne($TimeOut,$false)
        }
        catch [System.Net.Sockets.SocketException]
        {
            Write-Verbose " [Test-Port] :: Exception: $($_.exception.message)"
            Write-Verbose " [Test-Port] :: End"
            return $false
        }
        catch
        {
            Write-Verbose " [Test-Port] :: General Exception"
            Write-Verbose " [Test-Port] :: End"
            return $false
        }
    
        if(!$wait)
        {
            $tcpclient.Close()
            Write-Verbose " [Test-Port] :: Connection Timeout"
            Write-Verbose " [Test-Port] :: End"
            return $false
        }
        else
        {
            Write-Verbose " [Test-Port] :: Closing TCP Socket"
            try
            {
                $tcpclient.EndConnect($iar) | out-Null
                $tcpclient.Close()
            }
            catch
            {
                Write-Verbose " [Test-Port] :: Unable to Close TCP Socket"
            }
            $true
        }
    }
    End 
    {
        Write-Verbose " [Test-Port] :: End Script"
    }
}

<#
function function-template($i)
{
    if((Test-Connection -ComputerName $i -Quiet -Count 1) -eq $true)
    {

    }
    else
    {
        Call-Error_psf "Unable to connect to remote computer $i"
    }
}
#>

function check_psremoting
{
    if((Test-Path -Path "C:\Windows\System32\PsExec.exe") -eq $false)
    {
        Copy-Item -Path "\\SERVER\SHARE\...\PsExec.exe" -Destination "C:\Windows\System32\PsExec.exe" -Force
    }
}

function get_OSversion($i)
{
    $OS = Get-WmiObject -Class win32_operatingsystem -ComputerName $i
    $print = $OS.caption + " " + $OS.OSArchitecture
    return $print
}

function test_psremoting($i)
{
    try 
    {
		$result = Invoke-Command -ComputerName $i { 1 } -ErrorAction SilentlyContinue -AsJob -JobName "Test_PSRemoting"
		$int = 0
		while (($result.state -like "Running") -and ($int -lt 3))
		{
			Start-Sleep -Seconds 1
			$int++
		}
		if($result.State -like "Running") {$result | Stop-Job}
		$result | Receive-Job
		$result | Remove-Job
        if($result -eq 1 )
            {
                return $True
            }
            else
            {
                return $False
            }
    }
    catch 
    {
        return $False
    }
}


function test_RDP($i)
{
    if((Test-Port -TCPport 3389 -ComputerName $i) -eq $true)
    {
        return $true
    }
    else
    {
        return $false
    }
}

function get_uptime($i)
{
    $lastBoot = Get-WmiObject -Class win32_operatingsystem -ComputerName $i | Select-Object LastBootUpTime
    $dateTime = [Management.ManagementDateTimeConverter]::ToDateTime($lastBoot.lastbootuptime)
    $uptime = (Get-Date) - $dateTime
    $uptime = [string]$uptime.Days + " Days " + [string]$uptime.Hours + " Hours " + [string]$uptime.Minutes + " Minutes"
    return $uptime
}

function enable_remoting($i)
{
    Get-Service -ComputerName $i -Name winrm | Start-Service
    psexec -d \\$i powershell {winrm quickconfig -q}
}

function reset_pwr($i)
{
    $newpass = Show_InputBox "Enter new password`nMUST BE 8 CHARACTERS OR LONGER"
    if($newpass.length -lt 8)
    {
        return $false
    }
    $newpass = ConvertTo-SecureString -AsPlainText [string]$newpass -Force
    Set-ADAccountPassword -Identity $i -reset -NewPassword $newpass
    if($? -eq $false)
    {
        Call-Error_psf "Unable to reset password for user $i"
        Log_ToSplunk -Message "Unable to change password for $i" -Status "fail"
        return $false
    }
    else
    {
        Log_ToSplunk -Message "Succesfully changed password for $i" -Status "success"
        return $true
    }

}

function unlock_acct($i)
{
    Unlock-ADAccount -Identity $i
    if($? -eq $false)
    {
        Call-Error_psf "Unable to unlock $i's account"
        Log_ToSplunk -Message"Unable to unlock $i accounts" -Status "fail"
        return $false
    }
    else
    {
        Log_ToSplunk -Message "Succesfully unlocked $i account" -Status "success"
        return $true
    }
}

function repair_office($i)
{
    if((Test-Connection -ComputerName $i -Quiet -Count 1) -eq $true)
    {
        enable_remoting $i
        Invoke-Command -ComputerName $i -ScriptBlock {Start-Process -FilePath "C:\temp\silentrepair02010.bat"}
        Log_ToSplunk -Message "Started office repair on $i"
        return $true
    }
    else
    {
        return $false
    }
}

function repair_domaingrade($i)
{
    if($i.substring(4,3) -ne "tag")
    {
        Call-Error_psf "Computer specified is not a tag computer `nThis function is only to be run on tag computers"
        return $false
    }
    if((Test-Connection -ComputerName $i -Quiet -Count 1) -eq $true)
    {
        $store = $i.substring(0,4)
        $TKT = $store + "TKT"
        $path = "\\$i\C$\...\Domain,_Inc"

        $SPW = ConvertTo-SecureString -AsPlainText -Force -String "<password>"
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "DOMAIN\ORGSVC", $SPW
        Invoke-Command -ComputerName $i -Credential $cred -ScriptBlock{Get-Process -Name "DomainGrade" | Stop-Process -Force} | Out-Null

        Get-ChildItem -Path $path -Recurse | Where-Object {$_.name -eq "user.config"} | Remove-Item -Force
        if($? -eq $true)
        {
            Call-Information_Dialogue_psf "Succesfully removed corrupt user config file `nRebooting $i"
            Restart-Computer -ComputerName $i -Force
            Log_ToSplunk -Message "Succesfully repaired DomainGrade on $i" -Status "success"
            return $true
        }
        else 
        {
            Call-Error_psf "There was an error `nPlease try again"
            Log_ToSplunk -Message "Unable to repair DomainGrade on $i" -Status "fail"
            return $false
        }
    }
    else 
    {
        Call-Error_psf "Unable to connect to remote computer $i"
        return $false
    }
}

function Set_GCPrinter($i)
{
    if($i.substring(4,3) -ne "reg")
    {
        Call-Error_psf "Computer specified is not a register computer `nThis function is only to be run on register computers"
        return $false
    }
    if((Test-Connection -ComputerName $i -Quiet -Count 1) -eq $true)
    {
        $SPW = ConvertTo-SecureString -AsPlainText -Force -String "<password>"
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "DOMAIN\ORGSVC", $SPW
        #Creates Variables for login
        enable_remoting $i
        Invoke-Command -ComputerName $i -Credential $cred -ScriptBlock {
            Set-ItemProperty –Path HKLM:\Software\OLEForRetail\ServiceOPOS\POSPrinter –Name DefaultPOSPrinter –Value TM-H6000IVU
            Restart-Computer -Force
        }
        Call-Information_Dialogue_psf "Succesfully changed default printer of `n$i to H6000"
        Log_ToSplunk -Message "default print of $i changed to H6000"
        return $true
    }
    else
    {
        Call-Error_psf "Unable to connect to remote computer $i"
        return $false
    }
}

function Set_RecPrinter($i)
{
    if($i.substring(4,3) -ne "reg")
    {
        Call-Error_psf "Computer specified is not a register computer `nThis function is only to be run on register computers"
        return $false
    }
    if((Test-Connection -ComputerName $i -Quiet -Count 1) -eq $true)
    {
        $SPW = ConvertTo-SecureString -AsPlainText -Force -String "<password>"
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "DOMAIN\ORGSVC", $SPW
        #Creates Variables for login
        enable_remoting $i
        Invoke-Command -ComputerName $i -Credential $cred -ScriptBlock {
            Set-ItemProperty –Path HKLM:\Software\OLEForRetail\ServiceOPOS\POSPrinter –Name DefaultPOSPrinter –Value TM-T88VU
            Restart-Computer -Force
        }
        Call-Information_Dialogue_psf "Succesfully changed default printer of `n$i to TM-88"
        Log_ToSplunk -Message "default print of $i changed to TM88"
        return $true
    }
    else
    {
        Call-Error_psf "Unable to connect to remote computer $i"
        return $false
    }
}

function clear_printqueue($i)
{
    if($i.substring(4,3) -ne "tag")
    {
        Call-Error_psf "Computer specified is not a tag computer `nThis function is only to be run on tag computers"
        return
    }
    if((Test-Connection -ComputerName $i -Quiet -Count 1) -eq $true)
    {
        $printerinfo = Get-WmiObject -Class win32_printer -ComputerName $i
        if($printerinfo)
        {
            try 
            {
                $printerinfo | foreach{$_.CancelAllJobs()}
                Start-Sleep -Seconds 2
                $printerinfo | foreach{$_.Delete()}
                Start-Sleep -Seconds 2
                Restart-Computer -ComputerName $i -Force
                Call-Information_Dialogue_psf "Succesfully Cleared Print Queue `nRestarting $i"
                Log_ToSplunk -Message "Print queue cleared on $i"
                return $true
            }
            catch 
            {
                Call-Error_psf "Unable to clear print queue `nPlease try again"
                return $false
            }
        }
    }
}

function Fix_SQL($i)
{
    if((Test-Connection -ComputerName $i -Quiet -Count 1) -eq $true)
    {
        $service = Get-Service -ComputerName $i -Name "MSSQL`$SQLEXPRESS"
        if($service.Status -eq "Running")
        {
            $service | Restart-Service -Force
            $service | Set-Service -StartupType Automatic
            Log_ToSplunk -Message "Restarted SQL service on $i"
            return $true
        }
        else 
        {
            $service | Start-Service
            $service | Set-Service -StartupType Automatic
            Log_ToSplunk -Message "Started SQL service on $i"
            return $true
        }
    }
    else
    {
        Call-Error_psf "Unable to connect to remote computer $i"
        return $false
    }
}

function Repair_Cornerstone($i)
{
    if((Test-Connection -ComputerName $i -Quiet -Count 1) -eq $true)
    {
        $path = "\\SERVER\SHARE\...\Install-Cornerstone.ps1"
        $dest = "\\$i\C$\...\Install-Cornerstone.ps1"
        Copy-Item -Path $path -Destination $dest -Force
		enable_remoting $i
        Invoke-Command -ComputerName $i -FilePath $dest
        if($?)
        {
            Call-Information_Dialogue_psf "Succesfully started cornerstone `nrepair process on $i"
            Log_ToSplunk -Message "Started cornerstone repair on $i"
            return $true
        }
        else 
        {
            Call-Error_psf "There was an issue `nPlease try again"
            Log_ToSplunk -Message "Unable to repair Cornerstone on $i" -Status "fail"
            return $false
        }
    }
    else
    {
        Call-Error_psf "Unable to connect to remote computer $i"
        return $false
    }
}

function toggle_proxy_remote($i)
{
    if((Test-Connection -ComputerName $i -Quiet -Count 1) -eq $true)
    {
        enable_remoting $i
        Invoke-Command -ComputerName $i -ScriptBlock {Get-Process -Name iexplore | Stop-Process -Force} -ErrorAction SilentlyContinue
        Invoke-Command -ComputerName $i -ScriptBlock{
            Set-Location "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
            if((Get-ItemProperty -name proxyenable -path .).proxyenable -eq "0")
            {
                Set-ItemProperty -Name proxyenable -Path . -Value 1
                Set-ItemProperty -Name proxyserver -Path . -Value "domainisa1:8080"
                Set-ItemProperty -Name proxyoverride -Path . -Value "192.0.6.*;192.0.7.*;10.*.*.*;www.aircanada.ca;192.0.4.*;domainnet;*ebs*.example.com;www.hrsdc-rhdcc.gc.ca;blrscr3.egs.seg.gc.ca;0.0.0.0;*.rrd.com;*.rrdvenue.com;domainarc1.example.com;*bi*.example.com;myhr.example.com;myhrtest.example.com;www.domainwebmail.com; <local>"
                Call-Information_Dialogue_psf "Proxy is now enabled on $i"
                return $true
                break
            }
            if((Get-ItemProperty -name proxyenable -path .).proxyenable -eq "1")
            {
                Set-ItemProperty -Name proxyenable -Path . -Value 0
                Call-Information_Dialogue_psf "proxy is now disabled on $i"
                return $true
                break
            }
        }
        if($? -eq $false)
        {
            Call-Error_psf "There was a problem executing this function `nPlease try again"
            return $false
        }
    }
    else
    {
        Call-Error_psf "Unable to connect to remote computer $i"
        return $false
    }
}

function rename_computer($i)
{
    if((Test-Connection -ComputerName $i -Quiet -Count 1) -eq $true)
    {
        $newname = Show_InputBox "New Computer Name"
        if($newname -eq "")
        {
            return $false
        }
        Rename-Computer -ComputerName $i -NewName $newname -Force
        if($? -eq $true)
        {
            Call-Information_Dialogue_psf "$i renamed to $newname"
            Log_ToSplunk -Message "Computer $i renamed to $newname"
            return $true
        }
        else 
        {
            Call-Error_psf "Unable to rename $i `nPlease try again"
            return $false
        }
    }
    else
    {
        Call-Error_psf "Unable to connect to remote computer $i"
        return $false
    }
}

function get_dartspassword
{
    # (Day + Month + Year - 1900) * 2
    $date = Get-Date
    $pswd = ($date.day + $date.Month + $date.Year - 1900) * 2
    Log_ToSplunk -Message "Generated setup password" | out-null
    return $pswd
}

Function Get-TKTpass($store)
{
	$cubed = [Math]::Pow($store, 3)
	$hexNum = [Convert]::ToString($cubed, 16)
	$tktPassword = $hexNum.ToUpper()
    return $tktPassword
}

function set_taglogin($i)
{
	if($i.substring(4,3) -ne "tag")
	{
		Call-Error_psf "$i is not a tag computer, please try again."
		return $false
	}
	if(Test-Connection -ComputerName $i -Count 1 -Quiet)
	{
		$store = $i.substring(0,4)
		$pass = Get-TKTpass $store
		$domain = "domain"
		$user = $store + "TKT"
		$SB = {
			$winlogon = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
			Set-ItemProperty -Path $winlogon -Name "AutoAdminLogon" -Value "1"
			Set-ItemProperty -Path $winlogon -Name "DefaultDomainName" -Value $domain
			Set-ItemProperty -Path $winlogon -Name "DefaultUserName" -Value $user
			Set-ItemProperty -Path $winlogon -Name "DefaultPassword" -Value $pass
		}
		enable_remoting $i
		Invoke-Command -ScriptBlock $SB -ArgumentList $domain,$user,$pass
		if($?)
		{
			Log_ToSplunk -Message "AutoAdmin logon enabled on $i" -Status "success"
			Restart-Computer -ComputerName $i -Force
			return $true
		}
		else 
		{
			Log_ToSplunk -Message "Unable to set AutoAdmin logon on $i" -Status "fail"
			return $false
		}
	}
	else 
	{
		return $false
	}
}

function Reset_HierarchyFiles($i)
{
	if($i.substring(4,3) -ne "tag")
	{
		Call-Error_psf "$i is not a tag computer, please try again."
		return $false
	}
	$files = Get-ChildItem -Path "\\$i\C$\Program Files\Domain, Inc\DomainGrade" | Where-Object { $_.Extension -eq ".xml" }
	if($files -eq $null)
	{
		Log_ToSplunk -Message "Hierarchy files not found on $i"
		return $false
	}
	foreach($file in $files)
	{
		if($file.Name.Substring(0,9) -eq "hierarchy")
		{
			#Write-Host $file.FullName
			Remove-Item -Path $file.FullName -Force 
		}
	}
	Log_ToSplunk -Message "Hierarchy files reset on $i" -Status "Success"
	Restart-Computer -ComputerName $i -Force
	return $true
}

function set-homepath
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $computer
    )
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

    $store = $computer.substring(0,4)
    $str = $store + "str"
    $mgr = $store + "mgr"
    
    $parentpath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\'
    $items = Get-ChildItem $parentpath | Get-ItemProperty | Select-Object -Property pschildname
    $SIDs = @()
    foreach($item in $items)
    {
        $SIDs += $item.pschildname
    }
    
    $strmatch = 0
    $mgrmatch = 0
    foreach($SID in $SIDs)
    {
        $path = $parentpath + $SID
        if((Get-ItemProperty -Path $path -Name profileimagepath).profileimagepath.substring(9,7).trim() -eq $str)
        {
            $strmatch++
            $shellpath = "HKU:\$($SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
            Set-ItemProperty -Path $shellpath -Name "Personal" -Value "\\$($store)ST\Docs" -Force
            Set-ItemProperty -Path $shellpath -Name "My Pictures" -Value "\\$($store)ST\Docs\StorePictures" -Force
            $usershellpath = "HKU:\$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
            Set-ItemProperty -Path $usershellpath -Name "Personal" -Value "\\$($store)ST\Docs" -Force
            Set-ItemProperty -Path $usershellpath -Name "My Pictures" -Value "\\$($store)ST\Docs\StorePictures" -Force
        }
        elseif((Get-ItemProperty -Path $path -Name profileimagepath).profileimagepath.substring(9,7).trim() -eq $mgr)
        {
            $mgrmatch++
            $shellpath = "HKU:\$($SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
            Set-ItemProperty -Path $shellpath -Name "Personal" -Value "\\$($store)ST\Docs" -Force
            Set-ItemProperty -Path $shellpath -Name "My Pictures" -Value "\\$($store)ST\Docs\StorePictures" -Force
            $usershellpath = "HKU:\$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
            Set-ItemProperty -Path $usershellpath -Name "Personal" -Value "\\$($store)ST\Docs" -Force
            Set-ItemProperty -Path $usershellpath -Name "My Pictures" -Value "\\$($store)ST\Docs\StorePictures" -Force
        }
    }
    Remove-PSDrive -Name HKU -Force
    $output = New-Object -TypeName psobject -Property @{
        StoreMatch = $strmatch
        ManagerMatch = $mgrmatch
    }
    return $output
}    

function set-mappeddrive
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $computer
    )
    $st = $computer.substring(0,4) + "ST"
    NET USE r: /delete
    Start-Sleep -Seconds 5
    NET USE r: "\\$st\Reports" /persistent:yes
    
    if(Get-PSDrive -PSProvider FileSystem | Where-Object {$_.root -eq "R:\"})
    {
        return $true
    }
    else 
    {
        return $false
    }
}

function sync-scripts
{
	[CmdletBinding()]
	Param
	(
		[parameter(Mandatory=$true,
		position=0)]
		$computer
	)
	$machinelist = @()
	$machinelist += "st"
	$machinelist += "js"
	$machinelist += "s2"
	$machinelist += "s3"
	$machinetype = $computer.substring(4,2)
	if ($machinelist -notcontains $machinetype)
	{
		call-error_psf "$computer is not a store machine, please try again"
	}
	else
	{
		$job = start-job -scriptblock {Robocopy.exe "\\srv\logon$\Scripts" "\\$computer\C$\Scripts" /E}
		Log_ToSplunk -Message "Syncing C:\Scripts folder on $computer"
		return $job
	}
}

# ----------------------------------------------------------------------------------------------
# GUI Functions

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
	$buttonOK.DialogResult = 'Cancel'
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

function Show_InputBox {
    Param([string]$message=$(Throw "You must enter a prompt message"),
          [string]$title="Input",
          [string]$default
          )
          
    [reflection.assembly]::loadwithpartialname("microsoft.visualbasic") | Out-Null
    [microsoft.visualbasic.interaction]::InputBox($message,$title,$default)
    
}

function Call-ServiceDeskTools_psf {

	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=0.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Data, Version=0.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Drawing, Version=0.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	[void][reflection.assembly]::Load('System.Design, Version=0.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$formServiceDeskTools = New-Object 'System.Windows.Forms.Form'
	$groupbox8 = New-Object 'System.Windows.Forms.GroupBox'
	$buttonSetReceiptPrinter = New-Object 'System.Windows.Forms.Button'
	$buttonSetGiftCertificatePr = New-Object 'System.Windows.Forms.Button'
	$groupbox7 = New-Object 'System.Windows.Forms.GroupBox'
	$buttonResetHierarchyFiles = New-Object 'System.Windows.Forms.Button'
	$buttonRepairDomainGrade = New-Object 'System.Windows.Forms.Button'
	$buttonSetTagAutoLogin = New-Object 'System.Windows.Forms.Button'
	$buttonClearPrintQueue = New-Object 'System.Windows.Forms.Button'
	$picturebox1 = New-Object 'System.Windows.Forms.PictureBox'
	$groupbox6 = New-Object 'System.Windows.Forms.GroupBox'
	$SetupPW = New-Object 'System.Windows.Forms.Label'
	$buttonRefresh = New-Object 'System.Windows.Forms.Button'
	$ActionStatus = New-Object 'System.Windows.Forms.Label'
	$labelAction = New-Object 'System.Windows.Forms.Label'
	$groupbox5 = New-Object 'System.Windows.Forms.GroupBox'
	$buttonMicrosoftRDP = New-Object 'System.Windows.Forms.Button'
	$buttonLANDeskRemoteControl = New-Object 'System.Windows.Forms.Button'
	$groupbox2 = New-Object 'System.Windows.Forms.GroupBox'
	$User = New-Object 'System.Windows.Forms.TextBox'
	$buttonUnlockADAccount = New-Object 'System.Windows.Forms.Button'
	$buttonResetADPassword = New-Object 'System.Windows.Forms.Button'
	$groupbox1 = New-Object 'System.Windows.Forms.GroupBox'
	$SerialStatus = New-Object 'System.Windows.Forms.Label'
	$ModelStatus = New-Object 'System.Windows.Forms.Label'
	$ManufacturerStatus = New-Object 'System.Windows.Forms.Label'
	$labelSerial = New-Object 'System.Windows.Forms.Label'
	$labelModel = New-Object 'System.Windows.Forms.Label'
	$labelManufacturer = New-Object 'System.Windows.Forms.Label'
	$UptimeStatus = New-Object 'System.Windows.Forms.Label'
	$OSStatus = New-Object 'System.Windows.Forms.Label'
	$labelUptime = New-Object 'System.Windows.Forms.Label'
	$labelOS = New-Object 'System.Windows.Forms.Label'
	$PSRemotingStatus = New-Object 'System.Windows.Forms.Label'
	$RDPStatus = New-Object 'System.Windows.Forms.Label'
	$labelPSRemoting = New-Object 'System.Windows.Forms.Label'
	$labelRDP = New-Object 'System.Windows.Forms.Label'
	$PermissionStatus = New-Object 'System.Windows.Forms.Label'
	$ConnectionStatus = New-Object 'System.Windows.Forms.Label'
	$labelPermission = New-Object 'System.Windows.Forms.Label'
	$labelConnection = New-Object 'System.Windows.Forms.Label'
	$labelTargetComputer = New-Object 'System.Windows.Forms.Label'
	$buttonGetInfo = New-Object 'System.Windows.Forms.Button'
	$Computer = New-Object 'System.Windows.Forms.TextBox'
	$menustrip1 = New-Object 'System.Windows.Forms.MenuStrip'
	$groupbox3 = New-Object 'System.Windows.Forms.GroupBox'
	$buttonSyncScripts = New-Object 'System.Windows.Forms.Button'
	$buttonRestartComputer = New-Object 'System.Windows.Forms.Button'
	$buttonRepairOffice = New-Object 'System.Windows.Forms.Button'
	$buttonToggleProxy = New-Object 'System.Windows.Forms.Button'
	$buttonRepairCornerstoneNet = New-Object 'System.Windows.Forms.Button'
	$buttonUpdateGroupPolicy = New-Object 'System.Windows.Forms.Button'
	$buttonResetStorePermission = New-Object 'System.Windows.Forms.Button'
	$buttonRenameComputer = New-Object 'System.Windows.Forms.Button'
	$buttonRepairSQL = New-Object 'System.Windows.Forms.Button'
	$fileToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$exitToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$helpToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$aboutToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$Tooltip = New-Object 'System.Windows.Forms.ToolTip'
	$usefulLinksToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$dellWarrantyToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$lenovoWarrantyToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$brotherWarrantyToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$preferredBrowserToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$internetExplorerToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$firefoxToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$chromeToolStripMenuItem1 = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	$formServiceDeskTools_Load={
		#TODO: Initialize Form Controls here
		$Computer.Text = $ENV:COMPUTERNAME
		$SetupPW.Text = get_dartspassword
		
		if (!(Test-Path "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"))
		{
			$chromeToolStripMenuItem1.Enabled = $false
		}
		if (!(Test-Path "C:\Program Files\Mozilla Firefox\firefox.exe"))
		{
			$firefoxToolStripMenuItem1.Enabled = $false
		}
		
		$browsercheck = Get-ItemProperty -Path "HKLM:\SOFTWARE\ServiceDeskTools"
		if ($browsercheck.browser -eq $null)
		{
			Set-ItemProperty -Path "HKLM:\SOFTWARE\ServiceDeskTools" -Name "Browser" -Value "iexplore.exe" -Confirm:$false
			$script:preferredBrowser = "iexplore.exe"
			$internetExplorerToolStripMenuItem1.Checked=$true
		}
		elseif ($browsercheck.browser -eq "iexplore.exe")
		{
			$script:preferredBrowser = "iexplore.exe"
			$internetExplorerToolStripMenuItem1.Checked=$true
		}
		elseif ($browsercheck.browser -eq "iexplore.exe")
		{
			$script:preferredBrowser = "iexplore.exe"
			$internetExplorerToolStripMenuItem1.Checked = $true
		}
		elseif ($browsercheck.browser -eq "chrome.exe")
		{
			$script:preferredBrowser = "chrome.exe"
			$chromeToolStripMenuItem1.Checked=$true
		}
		elseif ($browsercheck.browser -eq "firefox.exe")
		{
			$script:preferredBrowser = "firefox.exe"
			$firefoxToolStripMenuItem1.Checked=$true
		}
		
		if ($browsercheck.Theme -eq "Light")
		{
			$lightToolStripMenuItem1.Checked = $true
		}
		if ($browsercheck.Theme -eq "Dark")
		{
			$darkToolStripMenuItem1.Checked = $true
		}
		if ($browsercheck.Theme -eq "Aesthetic")
		{
			$aESTHETICToolStripMenuItem1.Checked = $true
		}
		if ($browsercheck.Theme -eq "High Contrast")
		{
			$highContrastToolStripMenuItem1.Checked = $true
		}
	}
	
	
	$exitToolStripMenuItem1_Click={
		#TODO: Place custom script here
		$formServiceDeskTools.Close()
		Hide-Console
	}
	
	$aboutToolStripMenuItem1_Click={
		#TODO: Place custom script here
		[System.Windows.Forms.MessageBox]::Show("Service Desk Tools v$version`nUpdated: $UpdateDate`n`nAuthor: $Author`n","Service Desk Tools");
	}
	
	$buttonGetInfo_Click = {
		$computername = $Computer.Text
		if ((Test-Connection -ComputerName $computername -Quiet -Count 1) -eq $true)
		{
			$ConnectionStatus.Text = "OK"
			$ConnectionStatus.ForeColor = 'Green'
					
			if (Test-Path "\\$computername\c$")
			{
				$PermissionStatus.Text = "OK"
				$PermissionStatus.ForeColor = 'Green'
				
				if ((test_RDP $computername) -eq $true)
				{
					$RDPStatus.Text = "OPEN"
					$RDPStatus.ForeColor = 'Green'
				}
				else
				{
					$RDPStatus.Text = "CLOSED"
					$RDPStatus.ForeColor = 'Red'
				}
				
				if ((test_psremoting $computername) -eq $true)
				{
					$PSRemotingStatus.Text = "OPEN"
					$PSRemotingStatus.ForeColor = 'Green'
				}
				else
				{
					$PSRemotingStatus.Text = "CLOSED"
					$PSRemotingStatus.ForeColor = 'Red'
				}
				
				$OSStatus.Text = get_OSversion $computername
				$UptimeStatus.Text = get_uptime $computername
				$ManufacturerStatus.Text = (Get-WmiObject -ComputerName $computername -Class Win32_computersystem).Manufacturer
				$ManufacturerStatus.ForeColor = 'Blue'
				$ModelStatus.Text = (Get-WmiObject -ComputerName $computername -Class Win32_computersystem).Model
				$ModelStatus.ForeColor = 'Blue'
				$SerialStatus.Text = (Get-WmiObject -ComputerName $computername -Class Win32_bios).SerialNumber
				$SerialStatus.ForeColor = 'Blue'
				
			}
			else
			{
				$PermissionStatus.Text = "FAIL"
				$PermissionStatus.ForeColor = 'Red'
			}
		}
		else
		{
			$ConnectionStatus.Text = "FAIL"
			$ConnectionStatus.ForeColor = 'Red'
		}
	}
	
	
	$Computer_TextChanged={
		$ConnectionStatus.Text = ""
		$PermissionStatus.Text = ""
		$RDPStatus.Text = ""
		$PSRemotingStatus.Text = ""
		$OSStatus.Text = ""
		$UptimeStatus.Text = ""
		$ManufacturerStatus.Text = ""
		$ModelStatus.Text = ""
		$SerialStatus.Text = ""
	}
	
	$buttonLANDeskRemoteControl_Click = {
		$computername = $Computer.Text
		$process = $preferredBrowser
		$process = $script:preferredBrowser
		$arguments = "https://$computername" + ":4343"
		Start-Process $process $arguments
		$ActionStatus.Text = "Started LANDesk Remote Control session with $computername"
		Log_ToSplunk "started LANDesk remote session on $computername" "ServiceDeskTools" "log"
	}
	
	$buttonMicrosoftRDP_Click={
		$computername = $Computer.Text
		$port = ":3389"
		$command = "mstsc"
		$argument = "/v:$computername$port /admin"
		Start-Process $command $argument
		$ActionStatus.Text = "Started RDP session with $computername"
		Log_ToSplunk "started Microsoft RDP remote session on $computername" "ServiceDeskTools" "log"
	}
	
	$buttonResetADPassword_Click={
		$username = $User.Text
		$action = reset_pwr $username
		if ($action -eq $true)
		{
			$ActionStatus.Text = "$username -  Password Succesfully Reset"
		}
		else
		{
			$ActionStatus.Text = "$username - Password could not be reset"
		}
	}
	
	$buttonUnlockADAccount_Click={
		$username = $User.Text
		$action = unlock_acct $username
		if ($action -eq $true)
		{
			$ActionStatus.Text = "$username - Account unlocked"
		}
		else
		{
			$ActionStatus.Text = "$username - Account could not be unlocked"
		}
	}
	
	$buttonRepairOffice_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = ", Please Wait..."
		$action = repair_office $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "Office repair started on $computername"
		}
		else
		{
			$ActionStatus.Text = "Office repair could not be started on $computername"
		}
	}
	
	$buttonRepairDomainGrade_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = "Repairing DomainGrade, Please Wait..."
		$action = repair_domaingrade $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "Succesfully removed corrupt file - $computername rebooting..."
		}
		else
		{
			$ActionStatus.Text = "Could not repair domaingrade on $computername"
		}
	}
	
	$buttonSetGiftCertificatePr_Click={
		$computername = $Computer.Text
		$action = Set_GCPrinter $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "Default printer changes to HM6000 - $computername rebooting..."
		}
		else
		{
			$ActionStatus.Text = "Could not change default printer"
		}
	}
	
	$buttonSetReceiptPrinter_Click = {
		$computername = $Computer.Text
		$action = Set_RecPrinter $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "Default printer changes to TM88 - $computername rebooting..."
		}
		else
		{
			$ActionStatus.Text = "Could not change default printer"
		}
	}
	
	$buttonClearPrintQueue_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = "Clearing Print Queue, Please Wait..."
		$action = clear_printqueue $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "Print queue cleared - $computername rebooting..."
		}
		else
		{
			$ActionStatus.Text = "Could not clear print queue"
		}
	}
	
	$buttonRepairSQL_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = "Repairing SQL, Please Wait..."
		$action = Fix_SQL $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "SQL service started on $computername"
		}
		else
		{
			$ActionStatus.Text = "Could not start SQL service"
		}
	}
	
	$buttonRepairCornerstoneNet_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = "Repairing Cornerstone, Please Wait..."
		$action = Repair_Cornerstone $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "Cornerstone repair initiated on $computername"
		}
		else
		{
			$ActionStatus.Text = "Could not start Cornerstone repair"
		}
	}
	
	$buttonToggleProxy_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = "Toggling Proxy Settings, Please Wait..."
		$action = toggle_proxy_remote $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "Proxy settings toggled on $computername"
		}
		else
		{
			$ActionStatus.Text = "Could not toggle proxy settings"
		}
	}
	
	$buttonRenameComputer_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = "Renaming $computername, Please Wait..."
		$action = rename_computer $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "$computername succesfully renamed"
		}
		else
		{
			$ActionStatus.Text = "Could not rename $computername"
		}
	}
	
	$buttonRestartComputer_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = "Restarting $computername, Please Wait..."
		Restart-Computer -ComputerName $computername -Force
		if ($? -eq $false)
		{
			$ActionStatus.Text = "Unable to reboot $computername"
		}
		else
		{
			$ActionStatus.Text = "$computername rebooting..."
		}
	}
	
	$buttonSetTagAutoLogin_Click = {
		$computername = $Computer.Text
		$ActionStatus.Text = "Setting Auto Login, Please Wait..."
		$action = set_taglogin $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "Auto Admin Logon set on $computername"
		}
		else
		{
			$ActionStatus.Text = "Could not set Auto Admin Logon on $computername"
		}
	}
	
	$buttonResetHierarchyFiles_Click = {
		$computername = $Computer.Text
		$ActionStatus.Text = "Performing Hierarchy File Reset, Please Wait..."
		$action = Reset_HierarchyFiles $computername
		if ($action -eq $true)
		{
			$ActionStatus.Text = "Hierarchy files reset on $computername - Rebooting machine"
		}
		else
		{
			$ActionStatus.Text = "Could not reset hierarchy files on $computername"
		}
		
	}
	
	$buttonRefresh_Click={
		$SetupPW.Text = get_dartspassword
	}
	
	$buttonResetStorePermission_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = "Performing Reset, Please Wait..."
		if (($computername.substring(4, 2) -eq "st") -or ($computername.Substring(4, 2) -eq "js") -or ($computername.Substring(4, 2) -eq "s2") -or ($computername.Substring(4, 2) -eq "s3"))
		{
			$action = Invoke-Command -ComputerName $computername -ScriptBlock ${function:set-homepath} -ArgumentList $computername
			if ($action.StoreMatch -gt 0)
			{
				Log_ToSplunk -Message "STR account permissions updated on $computername" -Status "success"
			}
			if ($action.ManagerMatch -gt 0)
			{
				Log_ToSplunk -Message "MGR account permissions updated on $computername" -Status "success"
			}
			$action2 = Invoke-Command -ComputerName $computername -ScriptBlock ${function:set-mappeddrive} -ArgumentList $computername
			if ($action2 = $true)
			{
				Log_ToSplunk -Message "R:\ drive mapped succesfully on $computername" -Status "success"
			}
			elseif ($action2 = $false)
			{
				Log_ToSplunk -Message "R:\ drive could not be mapped on $computername" -Status "fail"
			}
			$ActionStatus.Text = "Permissions reset on $computername"
		}
		else
		{
			Call-Error_psf "Computer specified is not a store computer`nPlease try again"
		}
	}
	
	$buttonUpdateGroupPolicy_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = "Updating Group Policy, Please Wait..."
		$action = Invoke-Command -ComputerName $computername -ScriptBlock {gpupdate /force}
		if ($action -eq $true)
		{
			$ActionStatus.Text = "Group Policy Updated on $computername"
		}
		else
		{
			$ActionStatus.Text = "Could Not Update Group Policy on $computername"
		}
	}
	
	$dellWarrantyToolStripMenuItem1_Click={
		$computername = $Computer.Text
		$process = $script:preferredBrowser
		$arguments = "http://www.dell.com/support/home/us/en/04/Products/?app=warranty"
		Start-Process $process $arguments
	}
	
	$lenovoWarrantyToolStripMenuItem1_Click={
		$computername = $Computer.Text
		$process = $script:preferredBrowser
		$arguments = "https://pcsupport.lenovo.com/us/en/warrantylookup"
		Start-Process $process $arguments
	}
	
	$brotherWarrantyToolStripMenuItem1_Click={
		$computername = $Computer.Text
		$process = $script:preferredBrowser
		$arguments = "https://www.brother-usa.com/brother-support"
		Start-Process $process $arguments
	}
	
	$labelAction_Click = {
		$computername = $Computer.Text
		$process = $script:preferredBrowser
		$arguments = "https://lmgtfy.com/"
		Start-Process $process $arguments
	}
	
	$buttonSyncScripts_Click={
		$computername = $Computer.Text
		$ActionStatus.Text = "Updating Scripts folder on $computername, please wait..."
		$action = sync-scripts -computer $computername
		
	}
	
	$internetExplorerToolStripMenuItem1_Click={
		Set-ItemProperty -Path "HKLM:\SOFTWARE\ServiceDeskTools" -Name "Browser" -Value "iexplore.exe"
		$script:preferredBrowser = "iexplore.exe"
		$internetExplorerToolStripMenuItem1.Checked = $true
		$chromeToolStripMenuItem1.Checked = $false
		$firefoxToolStripMenuItem1.Checked = $false
	}
	
	$firefoxToolStripMenuItem1_Click={
		Set-ItemProperty -Path "HKLM:\SOFTWARE\ServiceDeskTools" -Name "Browser" -Value "firefox.exe"
		$script:preferredBrowser = "firefox.exe"
		$internetExplorerToolStripMenuItem1.Checked = $false
		$chromeToolStripMenuItem1.Checked = $false
		$firefoxToolStripMenuItem1.Checked = $true
	}
	
	$chromeToolStripMenuItem1_Click={
		Set-ItemProperty -Path "HKLM:\SOFTWARE\ServiceDeskTools" -Name "Browser" -Value "chrome.exe"
		$script:preferredBrowser = "chrome.exe"
		$internetExplorerToolStripMenuItem1.Checked = $false
		$chromeToolStripMenuItem1.Checked = $true
		$firefoxToolStripMenuItem1.Checked = $false
		
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formServiceDeskTools.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonSetReceiptPrinter.remove_Click($buttonSetReceiptPrinter_Click)
			$buttonSetGiftCertificatePr.remove_Click($buttonSetGiftCertificatePr_Click)
			$buttonResetHierarchyFiles.remove_Click($buttonResetHierarchyFiles_Click)
			$buttonRepairDomainGrade.remove_Click($buttonRepairDomainGrade_Click)
			$buttonSetTagAutoLogin.remove_Click($buttonSetTagAutoLogin_Click)
			$buttonClearPrintQueue.remove_Click($buttonClearPrintQueue_Click)
			$picturebox1.remove_Click($picturebox1_Click)
			$buttonRefresh.remove_Click($buttonRefresh_Click)
			$labelAction.remove_Click($labelAction_Click)
			$buttonMicrosoftRDP.remove_Click($buttonMicrosoftRDP_Click)
			$buttonLANDeskRemoteControl.remove_Click($buttonLANDeskRemoteControl_Click)
			$buttonUnlockADAccount.remove_Click($buttonUnlockADAccount_Click)
			$buttonResetADPassword.remove_Click($buttonResetADPassword_Click)
			$buttonGetInfo.remove_Click($buttonGetInfo_Click)
			$Computer.remove_TextChanged($Computer_TextChanged)
			$buttonSyncScripts.remove_Click($buttonSyncScripts_Click)
			$buttonRestartComputer.remove_Click($buttonRestartComputer_Click)
			$buttonRepairOffice.remove_Click($buttonRepairOffice_Click)
			$buttonToggleProxy.remove_Click($buttonToggleProxy_Click)
			$buttonRepairCornerstoneNet.remove_Click($buttonRepairCornerstoneNet_Click)
			$buttonUpdateGroupPolicy.remove_Click($buttonUpdateGroupPolicy_Click)
			$buttonResetStorePermission.remove_Click($buttonResetStorePermission_Click)
			$buttonRenameComputer.remove_Click($buttonRenameComputer_Click)
			$buttonRepairSQL.remove_Click($buttonRepairSQL_Click)
			$formServiceDeskTools.remove_Load($formServiceDeskTools_Load)
			$exitToolStripMenuItem1.remove_Click($exitToolStripMenuItem1_Click)
			$aboutToolStripMenuItem1.remove_Click($aboutToolStripMenuItem1_Click)
			$dellWarrantyToolStripMenuItem1.remove_Click($dellWarrantyToolStripMenuItem1_Click)
			$lenovoWarrantyToolStripMenuItem1.remove_Click($lenovoWarrantyToolStripMenuItem1_Click)
			$brotherWarrantyToolStripMenuItem1.remove_Click($brotherWarrantyToolStripMenuItem1_Click)
			$internetExplorerToolStripMenuItem1.remove_Click($internetExplorerToolStripMenuItem1_Click)
			$firefoxToolStripMenuItem1.remove_Click($firefoxToolStripMenuItem1_Click)
			$chromeToolStripMenuItem1.remove_Click($chromeToolStripMenuItem1_Click)
			$formServiceDeskTools.remove_Load($Form_StateCorrection_Load)
			$formServiceDeskTools.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formServiceDeskTools.SuspendLayout()
	$groupbox8.SuspendLayout()
	$groupbox7.SuspendLayout()
	$groupbox6.SuspendLayout()
	$groupbox5.SuspendLayout()
	$groupbox2.SuspendLayout()
	$groupbox1.SuspendLayout()
	$menustrip1.SuspendLayout()
	$groupbox3.SuspendLayout()
	#
	# formServiceDeskTools
	#
	$formServiceDeskTools.Controls.Add($groupbox8)
	$formServiceDeskTools.Controls.Add($groupbox7)
	$formServiceDeskTools.Controls.Add($picturebox1)
	$formServiceDeskTools.Controls.Add($groupbox6)
	$formServiceDeskTools.Controls.Add($ActionStatus)
	$formServiceDeskTools.Controls.Add($labelAction)
	$formServiceDeskTools.Controls.Add($groupbox5)
	$formServiceDeskTools.Controls.Add($groupbox2)
	$formServiceDeskTools.Controls.Add($groupbox1)
	$formServiceDeskTools.Controls.Add($labelTargetComputer)
	$formServiceDeskTools.Controls.Add($buttonGetInfo)
	$formServiceDeskTools.Controls.Add($Computer)
	$formServiceDeskTools.Controls.Add($menustrip1)
	$formServiceDeskTools.Controls.Add($groupbox3)
	$formServiceDeskTools.AcceptButton = $buttonGetInfo
	$formServiceDeskTools.AutoScaleDimensions = '6, 13'
	$formServiceDeskTools.AutoScaleMode = 'Font'
	$formServiceDeskTools.BackColor = 'Control'
	$formServiceDeskTools.BackgroundImageLayout = 'Stretch'
	$formServiceDeskTools.ClientSize = '1044, 621'
	$formServiceDeskTools.FormBorderStyle = 'FixedSingle'
	$formServiceDeskTools.Icon = ''
	$formServiceDeskTools.MainMenuStrip = $menustrip1
	$formServiceDeskTools.MaximizeBox = $False
	$formServiceDeskTools.Name = 'formServiceDeskTools'
	$formServiceDeskTools.StartPosition = 'CenterScreen'
	$formServiceDeskTools.Text = "Service Desk Tools v$version"
	$formServiceDeskTools.add_Load($formServiceDeskTools_Load)
	#
	# groupbox8
	#
	$groupbox8.Controls.Add($buttonSetReceiptPrinter)
	$groupbox8.Controls.Add($buttonSetGiftCertificatePr)
	$groupbox8.BackColor = 'Control'
	$groupbox8.Font = 'Microsoft Sans Serif, 10pt'
	$groupbox8.Location = '675, 355'
	$groupbox8.Name = 'groupbox8'
	$groupbox8.Size = '315, 125'
	$groupbox8.TabIndex = 17
	$groupbox8.TabStop = $False
	$groupbox8.Text = 'Register Computer Tools'
	#
	# buttonSetReceiptPrinter
	#
	$buttonSetReceiptPrinter.Font = 'Microsoft Sans Serif, 10pt'
	$buttonSetReceiptPrinter.Location = '9, 22'
	$buttonSetReceiptPrinter.Name = 'buttonSetReceiptPrinter'
	$buttonSetReceiptPrinter.Size = '300, 40'
	$buttonSetReceiptPrinter.TabIndex = 6
	$buttonSetReceiptPrinter.Text = 'Set Receipt Printer'
	$Tooltip.SetToolTip($buttonSetReceiptPrinter, 'Sets default printer to TM-88')
	$buttonSetReceiptPrinter.UseVisualStyleBackColor = $True
	$buttonSetReceiptPrinter.add_Click($buttonSetReceiptPrinter_Click)
	#
	# buttonSetGiftCertificatePr
	#
	$buttonSetGiftCertificatePr.Font = 'Microsoft Sans Serif, 10pt'
	$buttonSetGiftCertificatePr.Location = '9, 71'
	$buttonSetGiftCertificatePr.Name = 'buttonSetGiftCertificatePr'
	$buttonSetGiftCertificatePr.Size = '300, 40'
	$buttonSetGiftCertificatePr.TabIndex = 5
	$buttonSetGiftCertificatePr.Text = 'Set Gift Certificate Printer'
	$Tooltip.SetToolTip($buttonSetGiftCertificatePr, 'Sets Default printer to HM6000')
	$buttonSetGiftCertificatePr.UseVisualStyleBackColor = $True
	$buttonSetGiftCertificatePr.add_Click($buttonSetGiftCertificatePr_Click)
	#
	# groupbox7
	#
	$groupbox7.Controls.Add($buttonResetHierarchyFiles)
	$groupbox7.Controls.Add($buttonRepairDomainGrade)
	$groupbox7.Controls.Add($buttonSetTagAutoLogin)
	$groupbox7.Controls.Add($buttonClearPrintQueue)
	$groupbox7.BackColor = 'Control'
	$groupbox7.Font = 'Microsoft Sans Serif, 10pt'
	$groupbox7.Location = '675, 123'
	$groupbox7.Name = 'groupbox7'
	$groupbox7.Size = '315, 212'
	$groupbox7.TabIndex = 16
	$groupbox7.TabStop = $False
	$groupbox7.Text = 'Tag Computer Tools'
	#
	# buttonResetHierarchyFiles
	#
	$buttonResetHierarchyFiles.Font = 'Microsoft Sans Serif, 10pt'
	$buttonResetHierarchyFiles.Location = '6, 21'
	$buttonResetHierarchyFiles.Name = 'buttonResetHierarchyFiles'
	$buttonResetHierarchyFiles.Size = '300, 40'
	$buttonResetHierarchyFiles.TabIndex = 14
	$buttonResetHierarchyFiles.Text = 'Reset Hierarchy FIles'
	$Tooltip.SetToolTip($buttonResetHierarchyFiles, 'Deletes hierarchy files on target tag computer and initiates reboot')
	$buttonResetHierarchyFiles.UseVisualStyleBackColor = $True
	$buttonResetHierarchyFiles.add_Click($buttonResetHierarchyFiles_Click)
	#
	# buttonRepairDomainGrade
	#
	$buttonRepairDomainGrade.Font = 'Microsoft Sans Serif, 10pt'
	$buttonRepairDomainGrade.Location = '6, 67'
	$buttonRepairDomainGrade.Name = 'buttonRepairDomainGrade'
	$buttonRepairDomainGrade.Size = '300, 40'
	$buttonRepairDomainGrade.TabIndex = 4
	$buttonRepairDomainGrade.Text = 'Repair DomainGrade'
	$Tooltip.SetToolTip($buttonRepairDomainGrade, 'Removes corrupt DomainGrade user file and reboots the target computer')
	$buttonRepairDomainGrade.UseVisualStyleBackColor = $True
	$buttonRepairDomainGrade.add_Click($buttonRepairDomainGrade_Click)
	#
	# buttonSetTagAutoLogin
	#
	$buttonSetTagAutoLogin.Font = 'Microsoft Sans Serif, 10pt'
	$buttonSetTagAutoLogin.Location = '6, 113'
	$buttonSetTagAutoLogin.Name = 'buttonSetTagAutoLogin'
	$buttonSetTagAutoLogin.Size = '300, 40'
	$buttonSetTagAutoLogin.TabIndex = 13
	$buttonSetTagAutoLogin.Text = 'Set Tag Auto-Login'
	$Tooltip.SetToolTip($buttonSetTagAutoLogin, 'Sets a tag machine to use Auto Admin Logon')
	$buttonSetTagAutoLogin.UseVisualStyleBackColor = $True
	$buttonSetTagAutoLogin.add_Click($buttonSetTagAutoLogin_Click)
	#
	# buttonClearPrintQueue
	#
	$buttonClearPrintQueue.Font = 'Microsoft Sans Serif, 10pt'
	$buttonClearPrintQueue.Location = '6, 159'
	$buttonClearPrintQueue.Name = 'buttonClearPrintQueue'
	$buttonClearPrintQueue.Size = '300, 40'
	$buttonClearPrintQueue.TabIndex = 7
	$buttonClearPrintQueue.Text = 'Clear Print Queue'
	$Tooltip.SetToolTip($buttonClearPrintQueue, 'Clears print queue, removes all printer and restarts a tag machine')
	$buttonClearPrintQueue.UseVisualStyleBackColor = $True
	$buttonClearPrintQueue.add_Click($buttonClearPrintQueue_Click)
	#
	# picturebox1
	#
	$picturebox1.BackColor = 'Transparent'
	#region Binary Data
	$picturebox1.BackgroundImage = 'D:\Source\Workspaces\A-Team\Service Desk\ServiceDeskToolsGUI\ServiceDeskToolsGUI\bin\Debug\DomainLogo.png'
	#endregion
	$picturebox1.BackgroundImageLayout = 'Stretch'
	$picturebox1.Location = '857, 573'
	$picturebox1.Name = 'picturebox1'
	$picturebox1.Size = '175, 36'
	$picturebox1.TabIndex = 10
	$picturebox1.TabStop = $False
	$picturebox1.add_Click($picturebox1_Click)
	#
	# groupbox6
	#
	$groupbox6.Controls.Add($SetupPW)
	$groupbox6.Controls.Add($buttonRefresh)
	$groupbox6.BackColor = 'Control'
	$groupbox6.Font = 'Microsoft Sans Serif, 10pt'
	$groupbox6.Location = '880, 26'
	$groupbox6.Name = 'groupbox6'
	$groupbox6.Size = '152, 90'
	$groupbox6.TabIndex = 9
	$groupbox6.TabStop = $False
	$groupbox6.Text = 'Setup Password'
	#
	# SetupPW
	#
	$SetupPW.AutoSize = $True
	$SetupPW.Location = '65, 25'
	$SetupPW.Name = 'SetupPW'
	$SetupPW.Size = '0, 17'
	$SetupPW.TabIndex = 1
	#
	# buttonRefresh
	#
	$buttonRefresh.Font = 'Microsoft Sans Serif, 10pt'
	$buttonRefresh.Location = '7, 54'
	$buttonRefresh.Name = 'buttonRefresh'
	$buttonRefresh.Size = '139, 29'
	$buttonRefresh.TabIndex = 0
	$buttonRefresh.Text = 'Refresh'
	$buttonRefresh.UseVisualStyleBackColor = $True
	$buttonRefresh.add_Click($buttonRefresh_Click)
	#
	# ActionStatus
	#
	$ActionStatus.AutoSize = $True
	$ActionStatus.Font = 'Microsoft Sans Serif, 12pt'
	$ActionStatus.Location = '79, 586'
	$ActionStatus.Name = 'ActionStatus'
	$ActionStatus.Size = '0, 20'
	$ActionStatus.TabIndex = 8
	#
	# labelAction
	#
	$labelAction.AutoSize = $True
	$labelAction.Font = 'Microsoft Sans Serif, 12pt'
	$labelAction.Location = '13, 586'
	$labelAction.Name = 'labelAction'
	$labelAction.Size = '62, 20'
	$labelAction.TabIndex = 7
	$labelAction.Text = 'Action: '
	$labelAction.add_Click($labelAction_Click)
	#
	# groupbox5
	#
	$groupbox5.Controls.Add($buttonMicrosoftRDP)
	$groupbox5.Controls.Add($buttonLANDeskRemoteControl)
	$groupbox5.BackColor = 'Control'
	$groupbox5.Font = 'Microsoft Sans Serif, 10pt'
	$groupbox5.Location = '13, 327'
	$groupbox5.Name = 'groupbox5'
	$groupbox5.Size = '333, 175'
	$groupbox5.TabIndex = 6
	$groupbox5.TabStop = $False
	$groupbox5.Text = 'Remote Management'
	#
	# buttonMicrosoftRDP
	#
	$buttonMicrosoftRDP.Font = 'Microsoft Sans Serif, 10pt'
	$buttonMicrosoftRDP.Location = '16, 93'
	$buttonMicrosoftRDP.Name = 'buttonMicrosoftRDP'
	$buttonMicrosoftRDP.Size = '300, 50'
	$buttonMicrosoftRDP.TabIndex = 1
	$buttonMicrosoftRDP.Text = 'Microsoft RDP'
	$Tooltip.SetToolTip($buttonMicrosoftRDP, 'Launches an RDP session to target computer')
	$buttonMicrosoftRDP.UseVisualStyleBackColor = $True
	$buttonMicrosoftRDP.add_Click($buttonMicrosoftRDP_Click)
	#
	# buttonLANDeskRemoteControl
	#
	$buttonLANDeskRemoteControl.Font = 'Microsoft Sans Serif, 10pt'
	$buttonLANDeskRemoteControl.Location = '16, 37'
	$buttonLANDeskRemoteControl.Name = 'buttonLANDeskRemoteControl'
	$buttonLANDeskRemoteControl.Size = '300, 50'
	$buttonLANDeskRemoteControl.TabIndex = 0
	$buttonLANDeskRemoteControl.Text = 'LANDesk Remote Control'
	$Tooltip.SetToolTip($buttonLANDeskRemoteControl, 'Launches LANDesk Remote Control Window in IE')
	$buttonLANDeskRemoteControl.UseVisualStyleBackColor = $True
	$buttonLANDeskRemoteControl.add_Click($buttonLANDeskRemoteControl_Click)
	#
	# groupbox2
	#
	$groupbox2.Controls.Add($User)
	$groupbox2.Controls.Add($buttonUnlockADAccount)
	$groupbox2.Controls.Add($buttonResetADPassword)
	$groupbox2.BackColor = 'Control'
	$groupbox2.Font = 'Microsoft Sans Serif, 10pt'
	$groupbox2.Location = '13, 122'
	$groupbox2.Name = 'groupbox2'
	$groupbox2.Size = '333, 181'
	$groupbox2.TabIndex = 5
	$groupbox2.TabStop = $False
	$groupbox2.Text = 'User Management Tools'
	#
	# User
	#
	$User.Location = '16, 27'
	$User.Name = 'User'
	$User.Size = '300, 23'
	$User.TabIndex = 4
	$User.Text = '<Enter Username Here>'
	#
	# buttonUnlockADAccount
	#
	$buttonUnlockADAccount.Font = 'Microsoft Sans Serif, 10pt'
	$buttonUnlockADAccount.Location = '16, 114'
	$buttonUnlockADAccount.Name = 'buttonUnlockADAccount'
	$buttonUnlockADAccount.Size = '300, 50'
	$buttonUnlockADAccount.TabIndex = 3
	$buttonUnlockADAccount.Text = 'Unlock AD Account'
	$Tooltip.SetToolTip($buttonUnlockADAccount, 'Unlocks specified user account')
	$buttonUnlockADAccount.UseVisualStyleBackColor = $True
	$buttonUnlockADAccount.add_Click($buttonUnlockADAccount_Click)
	#
	# buttonResetADPassword
	#
	$buttonResetADPassword.Font = 'Microsoft Sans Serif, 10pt'
	$buttonResetADPassword.Location = '16, 58'
	$buttonResetADPassword.Name = 'buttonResetADPassword'
	$buttonResetADPassword.Size = '300, 50'
	$buttonResetADPassword.TabIndex = 2
	$buttonResetADPassword.Text = 'Reset AD Password'
	$Tooltip.SetToolTip($buttonResetADPassword, 'Resets AD password of user')
	$buttonResetADPassword.UseVisualStyleBackColor = $True
	$buttonResetADPassword.add_Click($buttonResetADPassword_Click)
	#
	# groupbox1
	#
	$groupbox1.Controls.Add($SerialStatus)
	$groupbox1.Controls.Add($ModelStatus)
	$groupbox1.Controls.Add($ManufacturerStatus)
	$groupbox1.Controls.Add($labelSerial)
	$groupbox1.Controls.Add($labelModel)
	$groupbox1.Controls.Add($labelManufacturer)
	$groupbox1.Controls.Add($UptimeStatus)
	$groupbox1.Controls.Add($OSStatus)
	$groupbox1.Controls.Add($labelUptime)
	$groupbox1.Controls.Add($labelOS)
	$groupbox1.Controls.Add($PSRemotingStatus)
	$groupbox1.Controls.Add($RDPStatus)
	$groupbox1.Controls.Add($labelPSRemoting)
	$groupbox1.Controls.Add($labelRDP)
	$groupbox1.Controls.Add($PermissionStatus)
	$groupbox1.Controls.Add($ConnectionStatus)
	$groupbox1.Controls.Add($labelPermission)
	$groupbox1.Controls.Add($labelConnection)
	$groupbox1.BackColor = 'Control'
	$groupbox1.Location = '305, 28'
	$groupbox1.Name = 'groupbox1'
	$groupbox1.Size = '569, 88'
	$groupbox1.TabIndex = 4
	$groupbox1.TabStop = $False
	$groupbox1.Text = 'Target Information'
	#
	# SerialStatus
	#
	$SerialStatus.AutoSize = $True
	$SerialStatus.Location = '369, 61'
	$SerialStatus.Name = 'SerialStatus'
	$SerialStatus.Size = '0, 13'
	$SerialStatus.TabIndex = 17
	#
	# ModelStatus
	#
	$ModelStatus.AutoSize = $True
	$ModelStatus.Location = '216, 61'
	$ModelStatus.Name = 'ModelStatus'
	$ModelStatus.Size = '0, 13'
	$ModelStatus.TabIndex = 16
	#
	# ManufacturerStatus
	#
	$ManufacturerStatus.AutoSize = $True
	$ManufacturerStatus.Location = '81, 61'
	$ManufacturerStatus.Name = 'ManufacturerStatus'
	$ManufacturerStatus.Size = '0, 13'
	$ManufacturerStatus.TabIndex = 15
	#
	# labelSerial
	#
	$labelSerial.AutoSize = $True
	$labelSerial.Location = '324, 61'
	$labelSerial.Name = 'labelSerial'
	$labelSerial.Size = '39, 13'
	$labelSerial.TabIndex = 14
	$labelSerial.Text = 'Serial: '
	#
	# labelModel
	#
	$labelModel.AutoSize = $True
	$labelModel.Location = '173, 61'
	$labelModel.Name = 'labelModel'
	$labelModel.Size = '39, 13'
	$labelModel.TabIndex = 13
	$labelModel.Text = 'Model:'
	#
	# labelManufacturer
	#
	$labelManufacturer.AutoSize = $True
	$labelManufacturer.Location = '7, 61'
	$labelManufacturer.Name = 'labelManufacturer'
	$labelManufacturer.Size = '73, 13'
	$labelManufacturer.TabIndex = 12
	$labelManufacturer.Text = 'Manufacturer:'
	#
	# UptimeStatus
	#
	$UptimeStatus.AutoSize = $True
	$UptimeStatus.Location = '368, 41'
	$UptimeStatus.Name = 'UptimeStatus'
	$UptimeStatus.Size = '0, 13'
	$UptimeStatus.TabIndex = 11
	#
	# OSStatus
	#
	$OSStatus.AutoSize = $True
	$OSStatus.Location = '351, 20'
	$OSStatus.Name = 'OSStatus'
	$OSStatus.Size = '0, 13'
	$OSStatus.TabIndex = 10
	#
	# labelUptime
	#
	$labelUptime.AutoSize = $True
	$labelUptime.Location = '324, 41'
	$labelUptime.Name = 'labelUptime'
	$labelUptime.Size = '43, 13'
	$labelUptime.TabIndex = 9
	$labelUptime.Text = 'Uptime:'
	#
	# labelOS
	#
	$labelOS.AutoSize = $True
	$labelOS.Location = '324, 20'
	$labelOS.Name = 'labelOS'
	$labelOS.Size = '25, 13'
	$labelOS.TabIndex = 8
	$labelOS.Text = 'OS:'
	#
	# PSRemotingStatus
	#
	$PSRemotingStatus.AutoSize = $True
	$PSRemotingStatus.Location = '244, 41'
	$PSRemotingStatus.Name = 'PSRemotingStatus'
	$PSRemotingStatus.Size = '0, 13'
	$PSRemotingStatus.TabIndex = 7
	#
	# RDPStatus
	#
	$RDPStatus.AutoSize = $True
	$RDPStatus.Location = '244, 20'
	$RDPStatus.Name = 'RDPStatus'
	$RDPStatus.Size = '0, 13'
	$RDPStatus.TabIndex = 6
	#
	# labelPSRemoting
	#
	$labelPSRemoting.AutoSize = $True
	$labelPSRemoting.Location = '173, 41'
	$labelPSRemoting.Name = 'labelPSRemoting'
	$labelPSRemoting.Size = '69, 13'
	$labelPSRemoting.TabIndex = 5
	$labelPSRemoting.Text = 'PSRemoting:'
	#
	# labelRDP
	#
	$labelRDP.AutoSize = $True
	$labelRDP.Location = '173, 20'
	$labelRDP.Name = 'labelRDP'
	$labelRDP.Size = '33, 13'
	$labelRDP.TabIndex = 4
	$labelRDP.Text = 'RDP:'
	#
	# PermissionStatus
	#
	$PermissionStatus.AutoSize = $True
	$PermissionStatus.Location = '94, 41'
	$PermissionStatus.Name = 'PermissionStatus'
	$PermissionStatus.Size = '0, 13'
	$PermissionStatus.TabIndex = 3
	#
	# ConnectionStatus
	#
	$ConnectionStatus.AutoSize = $True
	$ConnectionStatus.Location = '94, 20'
	$ConnectionStatus.Name = 'ConnectionStatus'
	$ConnectionStatus.Size = '0, 13'
	$ConnectionStatus.TabIndex = 2
	#
	# labelPermission
	#
	$labelPermission.AutoSize = $True
	$labelPermission.Location = '7, 41'
	$labelPermission.Name = 'labelPermission'
	$labelPermission.Size = '60, 13'
	$labelPermission.TabIndex = 1
	$labelPermission.Text = 'Permission:'
	#
	# labelConnection
	#
	$labelConnection.AutoSize = $True
	$labelConnection.Location = '7, 20'
	$labelConnection.Name = 'labelConnection'
	$labelConnection.Size = '64, 13'
	$labelConnection.TabIndex = 0
	$labelConnection.Text = 'Connection:'
	#
	# labelTargetComputer
	#
	$labelTargetComputer.AutoSize = $True
	$labelTargetComputer.BackColor = 'Control'
	$labelTargetComputer.Font = 'Microsoft Sans Serif, 12pt'
	$labelTargetComputer.Location = '100, 37'
	$labelTargetComputer.Name = 'labelTargetComputer'
	$labelTargetComputer.Size = '129, 20'
	$labelTargetComputer.TabIndex = 3
	$labelTargetComputer.Text = 'Target Computer'
	#
	# buttonGetInfo
	#
	$buttonGetInfo.Font = 'Microsoft Sans Serif, 10pt'
	$buttonGetInfo.Location = '13, 28'
	$buttonGetInfo.Name = 'buttonGetInfo'
	$buttonGetInfo.Size = '80, 80'
	$buttonGetInfo.TabIndex = 2
	$buttonGetInfo.Text = 'Get Info'
	$Tooltip.SetToolTip($buttonGetInfo, 'Gets information about target computer')
	$buttonGetInfo.UseVisualStyleBackColor = $True
	$buttonGetInfo.add_Click($buttonGetInfo_Click)
	#
	# Computer
	#
	$Computer.BackColor = 'Info'
	$Computer.Font = 'Microsoft Sans Serif, 16pt'
	$Computer.Location = '99, 68'
	$Computer.Name = 'Computer'
	$Computer.Size = '200, 32'
	$Computer.TabIndex = 1
	$Computer.TextAlign = 'Center'
	$Computer.add_TextChanged($Computer_TextChanged)
	#
	# menustrip1
	#
	[void]$menustrip1.Items.Add($fileToolStripMenuItem1)
	[void]$menustrip1.Items.Add($helpToolStripMenuItem1)
	[void]$menustrip1.Items.Add($usefulLinksToolStripMenuItem1)
	[void]$menustrip1.Items.Add($preferredBrowserToolStripMenuItem1)
	[void]$menustrip1.Items.Add($themesToolStripMenuItem1)
	$menustrip1.Location = '0, 0'
	$menustrip1.Name = 'menustrip1'
	$menustrip1.Size = '1044, 24'
	$menustrip1.TabIndex = 0
	$menustrip1.Text = 'menustrip1'
	#
	# groupbox3
	#
	$groupbox3.Controls.Add($buttonSyncScripts)
	$groupbox3.Controls.Add($buttonRestartComputer)
	$groupbox3.Controls.Add($buttonRepairOffice)
	$groupbox3.Controls.Add($buttonToggleProxy)
	$groupbox3.Controls.Add($buttonRepairCornerstoneNet)
	$groupbox3.Controls.Add($buttonUpdateGroupPolicy)
	$groupbox3.Controls.Add($buttonResetStorePermission)
	$groupbox3.Controls.Add($buttonRenameComputer)
	$groupbox3.Controls.Add($buttonRepairSQL)
	$groupbox3.BackColor = 'Control'
	$groupbox3.Font = 'Microsoft Sans Serif, 10pt'
	$groupbox3.Location = '352, 122'
	$groupbox3.Name = 'groupbox3'
	$groupbox3.Size = '316, 437'
	$groupbox3.TabIndex = 6
	$groupbox3.TabStop = $False
	$groupbox3.Text = 'Store Computer Tools'
	#
	# buttonSyncScripts
	#
	$buttonSyncScripts.Font = 'Microsoft Sans Serif, 10pt'
	$buttonSyncScripts.Location = '6, 390'
	$buttonSyncScripts.Name = 'buttonSyncScripts'
	$buttonSyncScripts.Size = '300, 40'
	$buttonSyncScripts.TabIndex = 17
	$buttonSyncScripts.Text = 'Sync Scripts'
	$Tooltip.SetToolTip($buttonSyncScripts, 'Syncs the C:\Scripts folder on the target machine with the host share on srv')
	$buttonSyncScripts.UseVisualStyleBackColor = $True
	$buttonSyncScripts.add_Click($buttonSyncScripts_Click)
	#
	# buttonRestartComputer
	#
	$buttonRestartComputer.Font = 'Microsoft Sans Serif, 10pt'
	$buttonRestartComputer.Location = '6, 206'
	$buttonRestartComputer.Name = 'buttonRestartComputer'
	$buttonRestartComputer.Size = '300, 40'
	$buttonRestartComputer.TabIndex = 12
	$buttonRestartComputer.Text = 'Restart Computer'
	$Tooltip.SetToolTip($buttonRestartComputer, 'Restarts target computer')
	$buttonRestartComputer.UseVisualStyleBackColor = $True
	$buttonRestartComputer.add_Click($buttonRestartComputer_Click)
	#
	# buttonRepairOffice
	#
	$buttonRepairOffice.Font = 'Microsoft Sans Serif, 10pt'
	$buttonRepairOffice.Location = '6, 252'
	$buttonRepairOffice.Name = 'buttonRepairOffice'
	$buttonRepairOffice.Size = '300, 40'
	$buttonRepairOffice.TabIndex = 3
	$buttonRepairOffice.Text = 'Repair Office'
	$Tooltip.SetToolTip($buttonRepairOffice, 'Launches an office repair on target computer')
	$buttonRepairOffice.UseVisualStyleBackColor = $True
	$buttonRepairOffice.add_Click($buttonRepairOffice_Click)
	#
	# buttonToggleProxy
	#
	$buttonToggleProxy.Font = 'Microsoft Sans Serif, 10pt'
	$buttonToggleProxy.Location = '6, 160'
	$buttonToggleProxy.Name = 'buttonToggleProxy'
	$buttonToggleProxy.Size = '300, 40'
	$buttonToggleProxy.TabIndex = 10
	$buttonToggleProxy.Text = 'Toggle Proxy'
	$Tooltip.SetToolTip($buttonToggleProxy, 'Toggles proxy settings on target computer')
	$buttonToggleProxy.UseVisualStyleBackColor = $True
	$buttonToggleProxy.add_Click($buttonToggleProxy_Click)
	#
	# buttonRepairCornerstoneNet
	#
	$buttonRepairCornerstoneNet.Font = 'Microsoft Sans Serif, 10pt'
	$buttonRepairCornerstoneNet.Location = '6, 68'
	$buttonRepairCornerstoneNet.Name = 'buttonRepairCornerstoneNet'
	$buttonRepairCornerstoneNet.Size = '300, 40'
	$buttonRepairCornerstoneNet.TabIndex = 9
	$buttonRepairCornerstoneNet.Text = 'Repair Cornerstone Network Player'
	$Tooltip.SetToolTip($buttonRepairCornerstoneNet, 'Reinstalls Cornerstone Network Pllayer on target computer')
	$buttonRepairCornerstoneNet.UseVisualStyleBackColor = $True
	$buttonRepairCornerstoneNet.add_Click($buttonRepairCornerstoneNet_Click)
	#
	# buttonUpdateGroupPolicy
	#
	$buttonUpdateGroupPolicy.Font = 'Microsoft Sans Serif, 10pt'
	$buttonUpdateGroupPolicy.Location = '6, 298'
	$buttonUpdateGroupPolicy.Name = 'buttonUpdateGroupPolicy'
	$buttonUpdateGroupPolicy.Size = '300, 40'
	$buttonUpdateGroupPolicy.TabIndex = 16
	$buttonUpdateGroupPolicy.Text = 'Update Group Policy'
	$buttonUpdateGroupPolicy.UseVisualStyleBackColor = $True
	$buttonUpdateGroupPolicy.add_Click($buttonUpdateGroupPolicy_Click)
	#
	# buttonResetStorePermission
	#
	$buttonResetStorePermission.Font = 'Microsoft Sans Serif, 10pt'
	$buttonResetStorePermission.Location = '6, 344'
	$buttonResetStorePermission.Name = 'buttonResetStorePermission'
	$buttonResetStorePermission.Size = '300, 40'
	$buttonResetStorePermission.TabIndex = 15
	$buttonResetStorePermission.Text = 'Reset Store Permissions'
	$Tooltip.SetToolTip($buttonResetStorePermission, 'Resets profile home location and sets mapped drives on target computer')
	$buttonResetStorePermission.UseVisualStyleBackColor = $True
	$buttonResetStorePermission.add_Click($buttonResetStorePermission_Click)
	#
	# buttonRenameComputer
	#
	$buttonRenameComputer.Font = 'Microsoft Sans Serif, 10pt'
	$buttonRenameComputer.Location = '6, 114'
	$buttonRenameComputer.Name = 'buttonRenameComputer'
	$buttonRenameComputer.Size = '300, 40'
	$buttonRenameComputer.TabIndex = 11
	$buttonRenameComputer.Text = 'Rename Computer'
	$Tooltip.SetToolTip($buttonRenameComputer, 'Renames target computer')
	$buttonRenameComputer.UseVisualStyleBackColor = $True
	$buttonRenameComputer.add_Click($buttonRenameComputer_Click)
	#
	# buttonRepairSQL
	#
	$buttonRepairSQL.Font = 'Microsoft Sans Serif, 10pt'
	$buttonRepairSQL.Location = '6, 22'
	$buttonRepairSQL.Name = 'buttonRepairSQL'
	$buttonRepairSQL.Size = '300, 40'
	$buttonRepairSQL.TabIndex = 8
	$buttonRepairSQL.Text = 'Repair SQL'
	$Tooltip.SetToolTip($buttonRepairSQL, 'Restarts or starts SQL service depending on status and sets startup type to Automatic')
	$buttonRepairSQL.UseVisualStyleBackColor = $True
	$buttonRepairSQL.add_Click($buttonRepairSQL_Click)
	#
	# fileToolStripMenuItem
	#
	[void]$fileToolStripMenuItem1.DropDownItems.Add($exitToolStripMenuItem1)
	$fileToolStripMenuItem1.Name = 'fileToolStripMenuItem1'
	$fileToolStripMenuItem1.Size = '37, 20'
	$fileToolStripMenuItem1.Text = 'File'
	#
	# exitToolStripMenuItem
	#
	$exitToolStripMenuItem1.Name = 'exitToolStripMenuItem1'
	$exitToolStripMenuItem1.Size = '152, 22'
	$exitToolStripMenuItem1.Text = 'Exit'
	$exitToolStripMenuItem1.add_Click($exitToolStripMenuItem1_Click)
	#
	# helpToolStripMenuItem
	#
	[void]$helpToolStripMenuItem1.DropDownItems.Add($aboutToolStripMenuItem1)
	$helpToolStripMenuItem1.Name = 'helpToolStripMenuItem1'
	$helpToolStripMenuItem1.Size = '44, 20'
	$helpToolStripMenuItem1.Text = 'Help'
	#
	# aboutToolStripMenuItem
	#
	$aboutToolStripMenuItem1.Name = 'aboutToolStripMenuItem1'
	$aboutToolStripMenuItem1.Size = '152, 22'
	$aboutToolStripMenuItem1.Text = 'About'
	$aboutToolStripMenuItem1.add_Click($aboutToolStripMenuItem1_Click)
	#
	# Tooltip
	#
	#
	# usefulLinksToolStripMenuItem
	#
	[void]$usefulLinksToolStripMenuItem1.DropDownItems.Add($dellWarrantyToolStripMenuItem1)
	[void]$usefulLinksToolStripMenuItem1.DropDownItems.Add($lenovoWarrantyToolStripMenuItem1)
	[void]$usefulLinksToolStripMenuItem1.DropDownItems.Add($brotherWarrantyToolStripMenuItem1)
	$usefulLinksToolStripMenuItem1.Name = 'usefulLinksToolStripMenuItem1'
	$usefulLinksToolStripMenuItem1.Size = '82, 20'
	$usefulLinksToolStripMenuItem1.Text = 'Useful Links'
	#
	# dellWarrantyToolStripMenuItem
	#
	$dellWarrantyToolStripMenuItem1.Name = 'dellWarrantyToolStripMenuItem1'
	$dellWarrantyToolStripMenuItem1.Size = '164, 22'
	$dellWarrantyToolStripMenuItem1.Text = 'Dell Warranty'
	$dellWarrantyToolStripMenuItem1.add_Click($dellWarrantyToolStripMenuItem1_Click)
	#
	# lenovoWarrantyToolStripMenuItem
	#
	$lenovoWarrantyToolStripMenuItem1.Name = 'lenovoWarrantyToolStripMenuItem1'
	$lenovoWarrantyToolStripMenuItem1.Size = '164, 22'
	$lenovoWarrantyToolStripMenuItem1.Text = 'Lenovo Warranty'
	$lenovoWarrantyToolStripMenuItem1.add_Click($lenovoWarrantyToolStripMenuItem1_Click)
	#
	# brotherWarrantyToolStripMenuItem
	#
	$brotherWarrantyToolStripMenuItem1.Name = 'brotherWarrantyToolStripMenuItem1'
	$brotherWarrantyToolStripMenuItem1.Size = '164, 22'
	$brotherWarrantyToolStripMenuItem1.Text = 'Brother Warranty'
	$brotherWarrantyToolStripMenuItem1.add_Click($brotherWarrantyToolStripMenuItem1_Click)
	#
	# preferredBrowserToolStripMenuItem
	#
	[void]$preferredBrowserToolStripMenuItem1.DropDownItems.Add($internetExplorerToolStripMenuItem1)
	[void]$preferredBrowserToolStripMenuItem1.DropDownItems.Add($firefoxToolStripMenuItem1)
	[void]$preferredBrowserToolStripMenuItem1.DropDownItems.Add($chromeToolStripMenuItem1)
	$preferredBrowserToolStripMenuItem1.Name = 'preferredBrowserToolStripMenuItem1'
	$preferredBrowserToolStripMenuItem1.Size = '112, 20'
	$preferredBrowserToolStripMenuItem1.Text = 'Preferred Browser'
	#
	# internetExplorerToolStripMenuItem
	#
	$internetExplorerToolStripMenuItem1.Name = 'internetExplorerToolStripMenuItem1'
	$internetExplorerToolStripMenuItem1.Size = '160, 22'
	$internetExplorerToolStripMenuItem1.Text = 'Internet Explorer'
	$internetExplorerToolStripMenuItem1.add_Click($internetExplorerToolStripMenuItem1_Click)
	#
	# firefoxToolStripMenuItem
	#
	$firefoxToolStripMenuItem1.Name = 'firefoxToolStripMenuItem1'
	$firefoxToolStripMenuItem1.Size = '160, 22'
	$firefoxToolStripMenuItem1.Text = 'Firefox'
	$firefoxToolStripMenuItem1.add_Click($firefoxToolStripMenuItem1_Click)
	#
	# chromeToolStripMenuItem
	#
	$chromeToolStripMenuItem1.Name = 'chromeToolStripMenuItem1'
	$chromeToolStripMenuItem1.Size = '160, 22'
	$chromeToolStripMenuItem1.Text = 'Chrome'
	$chromeToolStripMenuItem1.add_Click($chromeToolStripMenuItem1_Click)
	$groupbox3.ResumeLayout()
	$menustrip1.ResumeLayout()
	$groupbox1.ResumeLayout()
	$groupbox2.ResumeLayout()
	$groupbox5.ResumeLayout()
	$groupbox6.ResumeLayout()
	$groupbox7.ResumeLayout()
	$groupbox8.ResumeLayout()
	$formServiceDeskTools.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formServiceDeskTools.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formServiceDeskTools.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formServiceDeskTools.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formServiceDeskTools.ShowDialog()

}

# ----------------------------------------------------------------------------------------------
# Script

$themePath = "HKLM:\SOFTWARE\ServiceDeskTools"

Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

check_psremoting

Call-ServiceDeskTools_psf

#. (Join-Path $PSScriptRoot 'ServiceDeskTools.psf.ps1')
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"