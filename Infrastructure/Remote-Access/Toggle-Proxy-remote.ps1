<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 03/27/2017
    Organization: Domain, Inc.
    Filename: Toggle-Proxy-Remote.ps1
    Description: Remotely Toggles Proxy for user.
    =========================================================
    .VERSION
        v.1 - Intial Script

    .VERSION INFO
        [ENTER PREVIOUS VERSION INFO]
#>

<# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format "HHmmss"
$Script:Logfile = "C:\temp\#filename_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "VALUE, VALUE"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}
#>
# ----------------------------------------------------------------------------------------------
#Variables

$computer = Read-Host "Enter Computer Name"
#$iecheck = invoke-command -ComputerName $computer -ScriptBlock {Get-Process -Name "iexplore" -ErrorAction SilentlyContinue}
$connectiontest = Test-Connection -ComputerName $computer -quiet 

# ----------------------------------------------------------------------------------------------
#Functions

#starts winrm service and enables psremoting on the target machine.
function enable-remoting($computer)
{
    Get-Service -ComputerName $computer -Name winrm | Start-Service
    psexec -u domain\opsadmin -p "<password>" -d \\$computer powershell {winrm quickconfig -q}
}

#closes internet explorer on target machine.
function close-ie($computer)
{
    Invoke-Command -ComputerName $computer -ScriptBlock {Get-Process -Name iexplore | Stop-Process -Force} -ErrorAction SilentlyContinue
}

#depending on current settings, either enables proxy and sets all relevant settings or disables proxy.
function toggle-proxy($computer)
{
    Invoke-Command -ComputerName $computer -ScriptBlock{
        Set-Location "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
        if((Get-ItemProperty -name proxyenable -path .).proxyenable -eq "0")
        {
            Set-ItemProperty -Name proxyenable -Path . -Value 1
            Set-ItemProperty -Name proxyserver -Path . -Value "domainisa1:8080"
            Set-ItemProperty -Name proxyoverride -Path . -Value "192.0.6.*;192.0.7.*;10.*.*.*;www.aircanada.ca;192.0.4.*;domainnet;*ebs*.example.com;www.hrsdc-rhdcc.gc.ca;blrscr3.egs.seg.gc.ca;0.0.0.0;*.rrd.com;*.rrdvenue.com;domainarc1.example.com;*bi*.example.com;myhr.example.com;myhrtest.example.com;www.domainwebmail.com;<local>"
            Write-Host "Proxy is now enabled"
            break
        }
        if((Get-ItemProperty -name proxyenable -path .).proxyenable -eq "1")
        {
            Set-ItemProperty -Name proxyenable -Path . -Value 0
            Write-Host "Proxy is now disabled"
            break
        }
    } 
}

# ----------------------------------------------------------------------------------------------
#Script

if($connectiontest -eq $false)
{
    Write-Host "Computer Unreachable"
    break
}
else 
{
    enable-remoting $computer
    Write-Host "Remote Control Enabled"
    close-ie $computer
    Start-Sleep -Seconds 2
    toggle-proxy $computer
}

Write-Host "Press any key to continue..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")