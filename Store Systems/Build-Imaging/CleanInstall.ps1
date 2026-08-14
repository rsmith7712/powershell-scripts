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
    CleanInstall.ps1

.SYNOPSIS
  Domain Windows 10 IoT image deployment script for Fujitsu TP8000 POS hardware.
 
.DESCRIPTION
 CleanInstall.ps1 is a PowerShell script designed to execute from a Window PE environment in order to wipe and
 deploy Windows 10 IoT OS images and software to Fujitsu POS hardware from a USB thumb drive.

  Required files:
  (x:\ represents the path relative to an active WinPE session)
  (t:\ is relative path to the root of the usb drive during an active WinPE session.)
   x:\windows\system32\mountusb.txt (embedded in the boot.wim file.)
   x:\windows\system32\startnet.cmd (embedded in the boot.wim file.)
   x:\scripts\kickoff.ps1 (embedded in the boot.wim file.)
   NO LONGER IN USE --> t:\scripts\kickoff.bat (relative to the root of the usb drive.)

.NOTES
  Version:        2.3
  Author:         user10
  Modified Date:  09/6/2019
  Purpose/Change: Changed script logo to be more generic and just reflect the supported Fujitsu HW model rather than ticketing vs. register.

.HISTORY  
  Version:        2.2
  Author:         user10 (09/4/2019)
  Purpose/Change: Fixed file copy-related bugs.  Removed unnecessary code left over from the TP7000 script. Attempted to 
  clean up some of the formatting to make it more readable. Updated old TP7000 references to read TP8000.

  Version:        2.1
  Author:         user10(05/17/2019)
  Purpose/Change: Added SMBiosBiosVersion check to ensure this script is executed on the correct POS hardware.

  Version:        2.0
  Author:         user10 (03/08/2019)
  Purpose/Change: Modified script for Windows 10 IoT and Fujitsu TP8000.

  Version:        1.1
  Author:         user26(04/03/2018)
  Purpose/Change: Fixed bypass mode. Fancied up the user prompt and added recovery version number to it.

  Version:        1.0
  Author:         user26 (2015-01-26)
  Purpose/Change: Initial Script Development and first Production Version.

.FUNCTIONALITY
    CleanInstall.ps1 is a PowerShell script designed to execute from a Window PE environment in order to wipe and
     deploy Windows 10 IoT OS images and software to Fujitsu POS hardware from a USB thumb drive.

      Required files:
      (x:\ represents the path relative to an active WinPE session)
      (t:\ is relative path to the root of the usb drive during an active WinPE session.)
       x:\windows\system32\mountusb.txt (embedded in the boot.wim file.)
       x:\windows\system32\startnet.cmd (embedded in the boot.wim file.)
       x:\scripts\kickoff.ps1 (embedded in the boot.wim file.)
       NO LONGER IN USE --> t:\scripts\kickoff.bat (relative to the root of the usb drive.)

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Basic functions
$ErrorActionPreference = "SilentlyContinue"
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Function New-Header
{
    # PowerShell Window Size, Colors, and Title
    $pswindow = (get-host).ui.rawui
    $pswindow.windowtitle = "Domain Windows 10 IoT Image Deployment Script For Fujitsu TP8000 POS Hardware."
    $pswindow.foregroundcolor = "Blue"
    $pswindow.backgroundcolor = "Black"
	Write-Host ""
	Write-Host ""
	Write-Host ""
	Write-Host ""
	Write-Host ""
	Write-Host ""
	Write-Host ""
	Write-Host ""
    Write-Host "=============================================================="
    Write-Host "                     STORE SYSTEM SETUP                       "
    Write-Host "=============================================================="
}
# PowerShell Window Size, Colors, and Title
$pswindow = (get-host).ui.rawui
$pswindow.windowtitle = "Domain Windows 10 IoT Image Deployment Script For Fujitsu TP8000 POS Hardware."
$pswindow.foregroundcolor = "Blue"
$pswindow.backgroundcolor = "Black"
Clear-Host
#endregion
# Functions
Function Get-StoreNum
{
    $script:ipAddress = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'Description like "%I219-LM%"').ipaddress[0]    
   #$script:ipAddress = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'Description like "Microsoft Hyper-V Network Adapter"').ipaddress[0]
<#    
    $filter = "I219-LM","Microsoft Hyper-V Network Adapter"
    $filter | 
     ForEach-Object {
                        If (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'Description like "%$($filter)%"')
                        {
                            $script:ipAddress = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'Description like "%$($filter)%"').ipaddress[0]
                            # [PROD]
                            $script:ipAddress = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'Description like "%I219-LM%"').ipaddress[0]                            
                            #[TEST - HyperV]
                            $script:ipAddress = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'Description like "Microsoft Hyper-V Network Adapter"').ipaddress[0]
                        }
                    }
#>

$script:ipParsed = $script:ipAddress.split(".")
$ipParsed = $script:ipParsed
$thirdOct = $ipParsed[2]
$secondLength = $ipParsed[1].length
$thirdLength = $ipParsed[2].length
Switch($secondLength){
    2{ # Two Digits in 2nd Octet
        Switch($thirdLength){ # "New" IP Scheme
            1{#Adds a 0 for stores with a single digit 3rd octet like 1003
                $UFO_NUMBER = $ipParsed[1]+"0"+$ipParsed[2]
                $script:ipScheme = "2"
                Return $UFO_NUMBER
                }
            2{
                $UFO_NUMBER = $ipParsed[1]+$ipParsed[2]
                $script:ipScheme = "2"
                Return $UFO_NUMBER
                }
            3{# Offsite Production(Except 2001) will have a .1xx 3rd octet. ie, 2149A will be 10.21.149.xxx
                $subSite = $ipParsed[2].substring(1,2)
                $UFO_NUMBER = $ipParsed[1]+$subSite
                $script:ipScheme = "3"
                Return $UFO_NUMBER
                }
            }
        }
    3{ # Three Digits in 2nd Octet
        Switch($ipParsed[1]){ #Gets the prefix of the store based on the 2nd octet. "Old" IP Scheme
            "200"{$prefix = 2} #Canada
            "202"{$prefix = 1} #US VV and Domain
            "204"{$prefix = 3} #Australia
            "208"{$prefix = 5} #US Domain
            "210"{$prefix = 8} #US Partner3
            "151"{$prefix = 9} #Corporate (for development purposes only.)
            "100"{return "2001"} #CA 2001 WAREHOUSE
            "168"{return "9101"} #Test
            "209"{
                Switch($ipParsed[2]){
                    "50"{$labStore = "1950"}
                    "51"{$labStore = "1951"}
                    "55"{$labStore = "2955"}
                    "56"{$labStore = "1956"}
                    "59"{$labStore = "1959"}
                    "100"{$labStore = "2950"}
                    "101"{$labStore = "2951"}
                    "102"{$labStore = "2952"}
                    "109"{$labStore = "2959"}
                    "250"{$labStore = "3950"}
                    }
                Return $labStore
                }
            }
        Switch($thirdLength){ #Gets the rest of the UFO_NUMBER based on 3rd octet
            1{$suffix = "00$thirdOct"}
            2{$suffix = "0$thirdOct"}
            3{$suffix = "$thirdOct"}
            }
        $UFO_NUMBER = "$prefix"+"$suffix" #Combines to create UFO_NUMBER
        Write-Host $UFO_NUMBER -ForegroundColor Cyan
        return $UFO_NUMBER
        }
    }
}#===================[End Function]===================
Function Set-HostnameXML($xmlFolder,$computer)
{
    $xmlTemplate = "$($xmlFolder)\unattend_template.xml"
    $xmlFileName = "$($xmlFolder)\unattend.xml"
    [xml]$xmlDoc = New-Object system.Xml.XmlDocument
    [xml]$xmlDoc = Get-Content $xmlTemplate

    $Specialize_WindowsShellSetup = ($xmlDoc.unattend.settings |
     Where-Object{$_.Pass -eq 'specialize'}).component |
     Where-Object{$_.name -eq "Microsoft-Windows-Shell-Setup"}
    $Specialize_WindowsShellSetup.ComputerName = $computer
    $xmlDoc.Save($xmlFileName)
    return $?
}
#===================[End Function]===================
Function Get-Role
{
    [string]$store = Get-StoreNum
    Write-Host "Store Country ID = $store.substring(0,1)" -ForegroundColor Magenta
    $domainprefix = $store.substring(0,1)
    @("1","5","8","9") | 
     ForEach-Object {
                        if ($domainprefix -eq $_)
                        {
                            $options = @("Register : EN-US (1033)","Tag Machine : EN-US (1033)")
                            $role = Get-ListBox -title "Computer Role Selection" -msg "Please Select Register Computer or Tag (Ticketing) Machine." -options $options
                            switch ($role)
                            {
                                "Register : EN-US (1033)" {$r = "reg";$l = "1033"}
                                "Tag Machine : EN-US (1033)" {$r = "tag";$l = "1033"}
                            }
                        }
                    }
    if ($store.substring(0,1) -eq "2")
    {
        $options = @("Register : EN-CA (1033)","Register : FR-CA (3084)","Tag Machine : EN-CA (1033)","Tag Machine : FR-CA (3084)")
        $role = Get-ListBox -title "Computer Role Selection" -msg "Please Select Register Computer or Tag (Ticketing) Machine.`nThis is a Canadian Store, Please Select the Appropriate Language:" -options $options
        switch ($role)
        {
            "Register : EN-CA (1033)" {$r = "reg";$l = "1033"}
            "Register : FR-CA (3084)" {$r = "reg";$l = "3084"}
            "Tag Machine : EN-CA (1033)" {$r = "tag";$l = "1033"}
            "Tag Machine : FR-CA (3084)" {$r = "tag";$l = "3084"}
        }
    }
    if ($store.substring(0,1) -eq "3")
    {
        $options = @("Register : EN-AU(3081)","Tag Machine : EN-AU(3081)")
        $role = Get-ListBox -title "Computer Role Selection" -msg "Please Select Register Computer or Tag (Ticketing) Machine:" -options $options
        switch ($role)
        {
            "Register : EN-AU(3081)"{$r = "reg";$l = "3081"}
            "Tag Machine : EN-AU(3081)"{$r = "tag";$l = "3081"}
        }
    }
    Write-Host "ROLE: $role : $r : $l" -ForegroundColor Magenta
    return $r
}#===================[End Function]===================
Function Get-Designation($store,$role)
{
    $output = "Please Standby.  Getting available $($role) hostnames for Store: $($store)."
    Write-Host $output -ForegroundColor Cyan
    $hostnames = @()
    $n = @(1..5)
    $n | 
    ForEach-Object{
        $computer = $store + $role + $_
        
        if ((Test-Connection $computer -Quiet -count 1) -ne $true){$hostnames += $computer}
    }
    return $hostnames
}#===================[End Function]===================
Function Set-HostName
{
    Clear-Host
    New-Header
    $store = Get-StoreNum
    $role = Get-Role -store [string]$store
    $options = Get-Designation -store $store -role $role
    $computername = Get-ListBox -options $options -title "Hostname Selection" -msg "Please choose an available Hostname, then click 'OK':"
    if (($null -ne $computername))
    {
        $confirmhostname = Launch-MessageBox -msg "$computername has been selected as the new hostname for this computer.`n`nIs this correct?`n`nSelect 'No' to try again." "Confirmation" 4
        if (!($confirmhostname -eq "yes"))
        {
            $computername = $null
            Write-Host "Trying again..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            Set-HostName
        }
    return $computername
    }
        else
        {
            Set-HostName
        }
}#===================[End Function]===================
Function Check-Hardware()
{
    $wmi = Get-WmiObject -Class win32_bios
    #$manufacturer = $wmi.Manufacturer
    $smbiosver = $wmi.SMBiosBiosVersion
    if ($smbiosver.substring(0,4) -ne "S161")
    {
        Clear-Host
        Write-Host "          !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
        Write-Host "          !::::::::::::: FUJITSU TP8000 HARDWARE NOT DETECTED :::::::::::::!" -ForegroundColor Yellow
        Write-Host "          !::: THIS OS IMAGE IS INCOMPATIBLE WITH THE CURRENT HARDWARE ::::!" -ForegroundColor Yellow
        Write-Host "          !:::::::::::::::::::::::: EXITING SCRIPT ::::::::::::::::::::::::!" -ForegroundColor Yellow
        Write-Host "          !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
        Start-Sleep -Seconds 10
        EXIT 1
    }#---------------[End If]---------------
}#===================[End Function]===================
Function Copy-File
{
    param( [string]$from, [string]$to)
    $ffile = [io.file]::OpenRead($from)
    $tofile = [io.file]::OpenWrite($to)
    Write-Progress -Activity "Copying file" -status "$from -> $to" -PercentComplete 0
    try {
        [byte[]]$buff = new-object byte[] 4096
        [long]$total = [long]$count = 0
        do {
            $count = $ffile.Read($buff, 0, $buff.Length)
            $tofile.Write($buff, 0, $count)
            $total += $count
            if ($total % 1mb -eq 0) {
                Write-Progress -Activity "Copying file" -status "$from -> $to" `
                   -PercentComplete ([long]($total/$ffile.Length* 100))
            }
        } while ($count -gt 0)
    }
    finally {
        $ffile.Dispose()
        $tofile.Dispose()
    }
}#===================[End Function]===================
Function Launch-MessageBox($msg,$title,$options)
{ #Prompt the user with a box and return their response
    Add-Type -AssemblyName System.Windows.Forms
    $message = [System.Windows.Forms.MessageBox]::Show($msg,$title,$options)
    return $message
}#===================[End Function]===================
Function Get-ListBox($title,$msg,$options)
{
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(300,200)
    $form.StartPosition = 'CenterScreen'

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(75,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'OK'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(150,120)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = $($msg + ":")
    $form.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,40)
    $listBox.Size = New-Object System.Drawing.Size(260,20)
    $listBox.Height = 80
    
    $options|ForEach-Object{
        [void] $listBox.Items.Add("$_")
        }
    $form.Controls.Add($listBox)
    $form.Topmost = $true
    $result = $form.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $x = $listBox.SelectedItem
        $x
    }
}#===================[End Function]===================
Function Remove-Files($vol)
{
    Remove-Item -Path "$vol`Software" -Recurse -Force
    Remove-Item -Path "$vol`Scripts" -Recurse -Force
}#===================[End Function]===================

###################[SCRIPT STARTS]####################
Check-Hardware
# Parameters
#$installdate = Get-Date
Get-Volume|
ForEach-Object  {
                    $drivetype = $_.DriveType
		            $label = $_.FileSystemLabel
                    if(($label -eq "Windows") -and ($drivetype -eq "Fixed")){$WindowsVol = $_.DriveLetter}
                    if((Test-Path ($_.DriveLetter + ":\sources\boot.wim")) -and $drivetype -eq "Fixed"){$RecoveryVol = $_.DriveLetter + ":\"}
                    if((Test-Path ($_.DriveLetter + ":\*.wim"))-and $drivetype -eq "Fixed"){$RecoveryImageVol = $_.DriveLetter + ":\"}
                    if((Test-Path ($_.DriveLetter + ":\windows\system32")) -and $drivetype -eq "Removable"){$WinpeBootVol = $_.DriveLetter + ":\"}
                    if((Test-Path ($_.DriveLetter + ":\sources\boot.wim")) -and $drivetype -eq "Removable"){$UsbRootVol = $_.DriveLetter + ":\"}
                    if((Test-Path ($_.DriveLetter + ":\wim\*.wim")) -and $drivetype -eq "Removable"){$UsbImageVol = $_.DriveLetter + ":\"}
                }#---------------[End Foreach-Object]---------------
$WindowsInstall = $windowsvol + ":\"
$findwim = (Get-ChildItem $RecoveryImageVol).Name
$wimfile = $findwim|Select-String -Pattern ".wim"
$wimpath = $RecoveryImageVol + $wimfile
Clear
New-Header
# Request for computer hostname.
If (!(Test-Path "$recoveryvol`software")){mkdir "$recoveryvol`software"}
[string]$newname = Set-HostName
$UFO_NUMBER = $newname.Substring(0,4)
$r = $newname.Substring(4,3)
switch ($r)
{
    "reg"{$role = "REGISTER"}
    "tag"{$role = "TAG MACHINE"}
}
$lane =  $newname.toupper().Split("G")[1]
$xmlFolder = "$recoveryvol`scripts\config"
$status = Set-HostnameXML -xmlFolder $xmlFolder -computer $newname
Write-Host $status -ForegroundColor Yellow

$dism = "dism.exe"
$dismargs = "/apply-image /imagefile:$wimpath /index:1 /ApplyDir:$WindowsInstall"
Clear-Host
New-Header
Write-Host ""
Write-Host "Domain Store ID: $UFO_NUMBER" -ForegroundColor White
Write-Host "Role: $role" -ForegroundColor White
Write-Host "Lane Desgination: $lane" -ForegroundColor White
Write-Host "Hostname: $newname" -ForegroundColor Cyan
Write-Host "Windows OS Volume: $WindowsInstall" -ForegroundColor Yellow
Write-Host "Windows Recovery Root Volume: $recoveryvol" -ForegroundColor Yellow
Write-Host "USB Root Volume: $usbrootvol" -ForegroundColor Yellow
Write-Host "USB Image Volume: $usbimagevol" -ForegroundColor Yellow
Write-Host "Deploying Windows from Image File: $wimpath" -ForegroundColor White
Write-Host ""
Write-Host ""
$title = "Wipe and Image Fujitsu TP8000 POS Hardware"
$message = "This process will destroy all current data on the existing Windows partition. Do you want to continue?"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Wipes the existing Windows installation and deploys the Standard Domain MS Windows 10 IoT OS image for Fujitsu TP8000 POS hardware."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Aborts the install and reboots the computer. Select this option if you don't know what to do"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result)
{
    0
        {
            # Formats the existing windows partition.
            Format-Volume -DriveLetter $WindowsVol -FileSystem NTFS -Force -NewFileSystemLabel "Windows"
            # Images the Windows Partition.
            Clear-Host
            New-Header
            Write-Host ""
            Write-Host ""
            Write-Host "Imaging in progress; this may take 5 to 10 minutes."
            Start-Process $dism $dismargs -wait | Out-Null
            $bcdboot = "X:\Windows\System32\bcdboot.exe"
            $bcdbootargs = "D:\Windows /s C:"
            Start-Process $bcdboot $bcdbootmargs -wait | Out-Null
            If (Test-Path $usbrootvol)
            {
            # Delete old software and scripts directories from the recovery volume
            Remove-Files -vol $recoveryvol
                if (!(Test-Path "$recoveryvol`sources\boot.wim.fuj"))
                {
                    Rename-Item -Path "$recoveryvol`sources\boot.wim" -NewName "boot.wim.fuj" -Force
                }
                elseif (((Test-Path "$recoveryvol`sources\boot.wim.fuj") -eq $true) -and (Test-Path "$recoveryvol`sources\boot.wim.old") -eq $true)
                {
                    Remove-Item -Path "$recoveryvol`sources\boot.wim.old" -Force
                    Rename-Item -Path "$recoveryvol`sources\boot.wim" -NewName "boot.wim.old" -Force
                }
                    else
                    {
                        Rename-Item -Path "$recoveryvol`sources\boot.wim" -NewName "boot.wim.old"
                    }#---------------[End If-Elseif-Else]---------------
                Robocopy "$UsbRootVol`sources\" "$recoveryvol`sources\" "boot.wim" /w:1 /r:1
                Robocopy "$UsbRootVol`scripts" "$recoveryvol`scripts" /r:1 /w:1 /e
                Robocopy "$UsbRootVol`Software" "$recoveryvol`Software" /r:1 /w:1 /e 
            }#---------------[End If]---------------
            If (Test-Path "$recoveryvol`scripts")
            {
                if(!(Test-Path "$WindowsInstall`Windows\setup\scripts")){md "$WindowsInstall`Windows\setup\scripts"}
                if(!(Test-Path "$WindowsInstall`software")){md "$WindowsInstall`software"}
                
                Copy-Item "$recoveryvol`scripts\Config\setupcomplete_$($r).cmd" "$WindowsInstall`Windows\setup\scripts\setupcomplete.cmd" -Force
                Copy-Item "$recoveryvol`scripts\Config\Unattend.xml" "$WindowsInstall`Windows\Panther\Unattend.xml" -Force
                Copy-Item "$recoveryvol`scripts\Setup-TP8000_Software.lnk" "$WindowsInstall`ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Setup-TP8000_Software.lnk" -Force
                Robocopy "$recoveryvol`scripts" "$WindowsInstall`scripts" /r:1 /w:1 /e
                Robocopy "$recoveryvol`Software" "$WindowsInstall`Software" /r:1 /w:1 /e
            }
                else
                {
                    Write-Host "Unable to restore system from recovery partition.`Configuration files not found.`Exiting Script..."
                    Start-Sleep -Seconds 10
                    Exit
                }#---------------[End If-Else]---------------
            Clear-Host
            New-Header
            Write-Host ""
            Write-Host ""
            Write-Host "Imaging Complete"
            Write-Host "Time to complete: $($stopwatch.Elapsed)"
            Write-Host ""
            if (Test-Path $usbrootvol)
            {
                Write-Host "Remove the thumb drive if present, and hit any key to restart the computer."
                Write-Host "Alternatively, remove the thumb drive and hold down the power button to turn off."
                $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            Clear-Host
            New-Header
            Write-Host ""
            Write-Host ""
            Write-Host "Shutting down in 5 seconds"
            Start-Sleep -s 5
            Restart-Computer
        }#---------------[End Switch]---------------
    1 
        {
            # Abort dialogue
            Write-Host "You've selected No."
            Write-Host "Remove the thumb drive and hit any key to reboot"

            $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            Write-Host "Going down for a reboot in 5 seconds"
            Start-Sleep -s 5
            Restart-Computer
        }#---------------[End Switch]---------------
}#---------------[End Results Switches]---------------
####################[SCRIPT ENDS]#####################