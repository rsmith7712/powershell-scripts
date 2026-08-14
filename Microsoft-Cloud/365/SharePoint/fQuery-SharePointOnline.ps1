###########################################[FUNCTIONS ]############################################
Function Add-ModulePath ($DomainPSModules)
{
    $p = [Environment]::GetEnvironmentVariable("PSModulePath")
    $p += ";$DomainPSModules"
    [Environment]::SetEnvironmentVariable("PSModulePath",$p)
    $status = "[STATUS.Add-ModulePath] : SUCCESS=$($?). "
    return $status
}#=========================================[End Function ]=========================================
Function Connect-SPOnline()
{
    #test<#
    $script:spourl = "https://domain.sharepoint.com/sites/TheA-Team"
    $username = "flowautomation@example.com"
    $password = "<password>"
    #>

    #production
    <#
    $script:spourl = "https://domain.sharepoint.com/sites/DataStore"    
    $username = "svc_SlcCloudBackup@example.com"
    $password = "<password>"
    #>
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)

    $ErrorActionPreference = "stop"
    $reqModuleVer = '3.23.2007.1'
    Try
    {
        $moduleversion = (Import-Module "SharePointPnPPowerShellOnline" -PassThru -Force).Version
        $status = "[SUCCESS] : PS module 'SharePointPnPPowerShellOnline' version: $moduleversion imported successfully.";$color = "green";$splunkStatus = "Success"
    }
        Catch
        {
            $status = "[WARNING] : Failed to import PS module 'SharePointPnPPowerShellOnline.' The following exception occurred: $($_.Exception.Message).`n`n Attempting to install module.";$color = "yellow"
           <#
            [string]$src = "\\SERVER\SHARE\...\spo"
            [string]$dest = "C:\Scripts"
            [string]$pnpmsi = "SharePointOnlineManagementShell_20212-12000_x64_en-us.msi"
            Copy-Item -Path "$src\SharePointOnlineManagementShell_20212-12000_x64_en-us.msi" -Destination $dest -Force
            msiexec /i "$($dest)\$($pnpmsi)" /qn
            #>
        }
    Finally
    {
        #Process-Output -message $status -color $color -splunkLog $true -splunkType "Log" -splunkStatus $splunkStatus
        Write-Host $status -ForegroundColor $color
    }

    Try
    {
        $spConnection = Connect-PnPOnline -Url $spourl -Credentials $cred
        $status = "[SUCCESS] : Connection to SharePoint Online Successfully established";$color = "green";$splunkStatus = "Success"
    }
        Catch
        {
            $status = "[ERROR] : Failed to connect to $($spourl) as $($username). The following exception occurred: $($_.Exception.Message).";$color = "magenta";$splunkStatus = "Failure"
        }
    Finally
    {
        #Process-Output -message $status -color $color -splunkLog $true -splunkType "Log" -splunkStatus $splunkStatus
        Write-Host $status -ForegroundColor $color
    }
    $ErrorActionPreference = "stop"
}#=========================================[End Function ]=========================================

#########################################[ SCRIPT STARTS ]#########################################
#test<#
#[string]$UFO_NUMBER = "9998"
#[string]$slc = "srv-tmp-rc02"
#[string]$filename = "GlobalSTORE.bak.bz.TESTING123.txt"
#[string]$backupPath = "\\$($slc)\c$\scripts"
#[string]$backupFile = "$backupPath\$($filename)"
[string]$spoListName = "CorporateReports"
#>

#production<#
[string]$UFO_NUMBER = $($env:COMPUTERNAME).Substring(0,4)
[string]$slc = "$($UFO_NUMBER)SLC1"
[string]$backupFile = "\\$($slc)\c$\...\GlobalSTORE.bak.bz"
#[string]$spoListName = "stores"
#>
[string]$timestamp = ((Get-Date((Get-Item $backupfile).LastWriteTime).DateTime -format o).Replace(":","")).Split(".")[0]
#--------------------------------------------------------------------------------------------------
# Load module(s)
$source = "\\SERVER\SHARE\...\3.23.2007.1"
$destination = "C:\temp\Modules\SharePointPnPPowerShellOnline"
robocopy $source $destination /E /Z /W:1 /R:1
Add-ModulePath -DomainPSModules $destination
$spoConnection = Connect-SPOnline
Try
{
    $spoPath = "$($spoListName)\$($UFO_NUMBER)\$($timestamp)"
    Add-PnPFile -Path $backupfile -Folder $spoPath -Connection $spoConnection -erroraction "stop"
}
    Catch
    {
        $($_.Exception.Message)
    }
    $ErrorActionPreference = "SilentlyContinue"

##########################################[ SCRIPT ENDS ]##########################################
