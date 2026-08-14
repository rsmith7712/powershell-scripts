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
    Create-SharePointStoresFolderPnP3.ps1

.SYNOPSIS
  Bulk create folders with permission list via CSV import file with header names as [name] and [EmailAddress] from C:\temp\SharePointFolderNameList.csv   
  Example from the csv file content
      name,EmailAddress
      NewFolder1,user9admin@example.com 
 
.DESCRIPTION
  This script contains the following 3 functions: 
      Connect-SharePoint # Used to connect to the SharePoint site
      Create-FolderAndAddPermission # Used to create multiple folders with permission via CSV data feed
      Create-SingleFolderAndAddPermission $folderName $useralias # Used to create single folder 
  
.NOTES
  Version:        1.0 
  Modified by:	  
  Creation Date:  06/19/2019
  Purpose/Change: Initial Script Development 

.HISTORY
  Version:        1.0 
  Author:         Tony Chu
  Modified by:	  
  Creation Date:  06/19/2019
  Purpose/Change: Initial Script Development
  Version:        1.0

.FUNCTIONALITY
    This script contains the following 3 functions:
          Connect-SharePoint # Used to connect to the SharePoint site
          Create-FolderAndAddPermission # Used to create multiple folders with permission via CSV data feed
          Create-SingleFolderAndAddPermission $folderName $useralias # Used to create single folder

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Check Script is running with Elevated Privileges
Function Check-RunAsAdministrator()
{
  #Get current user context
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())

  #Check user is running the script is member of Administrator Group
  if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Write-host "Script is running with Administrator privileges!"
  }
  else
    {
       #Create a new Elevated process to Start PowerShell
       $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
       
       #Specify the current script path and name as a parameter
       $ElevatedProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
       
       #Set the Process to elevated
       $ElevatedProcess.Verb = "runas"

       #Start the new elevated process
       [System.Diagnostics.Process]::Start($ElevatedProcess)

       #Exit from the current, unelevated, process
       Exit
    }
}	

Check-RunAsAdministrator
#Read more: http://www.sharepointdiary.com/2015/01/run-powershell-script-as-administrator-automatically.html

# Initializations
$script:scriptFilepath = $MyInvocation.MyCommand.Path
$script:scriptDir = Split-Path -Parent $script:scriptFilepath
$errorActionPreference = "SilentlyContinue"
$Script:ProductName = "Create-SharePointFolder"
$Script:UID = [guid]::NewGuid()  
$ChangeDate = (Get-Date).AddDays(+1).ToString('MM/dd/yyyy')
$CsvFile = "C:\temp\SharePointStoresFolderNameList.csv"
$storeslist = "C:\Temp\storeslist3.csv"
$username = "flowautomation@example.com"
$password = "<password>"
$ListName = "StoreReports"
$WebAppURL = "https://domain.sharepoint.com/sites/ReportCenter"
$access = "Read" # "Full Control"
$datetime = (Get-Date).ToString('yyyyMMddHHmmss')
$folderName = "2016" # 1027, 1031, 2117, 3003 
$useralias = "user2@example.com"
$LogDir = "C:\Logs"
$script:LogFile = "C:\temp\CreateSharePointFolders3.log"

$source = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution\"
$sourcePDF = "\\SERVER\SHARE\...\REPORTS"
$previousYear = (Get-Date -Format yyyy) - 1 
$currentYear = Get-Date -Format yyyy
$sourcePreviousYear = $source + $previousYear 
$sourceCurrentYear = $source + $currentYear

# Install required SharePoint PnP Module 
Install-Module SharePointPnPPowerShellOnline -Force

# Local Logging
#################################
If(!(Test-Path $LogDir))
{
    New-Item -Path "c:\" -Name "Logs" -ItemType "directory"
}

If(!Test-Path $script:LogFile)
{
    New-Item $script:LogFile -type file -force
}

Function Write-Log($message)
{
    $dateTime = Get-Date -Format g
	Add-Content $script:LogFile "`n$dateTime : $message"
}

# Functions
#################################
Function Log_ToSplunk{
    Param(
    [parameter(Mandatory=$true,
    Position=0)]
    [String]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    [String]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    [String]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
    [String]
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

Function Connect-SharePoint{
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
    Connect-PnPOnline -Url $WebAppURL -Credentials $cred
}

Function Create-FolderAndAddPermission {
    # Import the CSV file. 
    Try {
        $FolderNameList = Import-Csv $CsvFile
    } 
    Catch 
    { 
        Write-Host "Invalid CSV file $CsvFile!!" -ForegroundColor Red -BackgroundColor Black 
        Write-Host "Script Aborted." -ForegroundColor Red -BackgroundColor Black 
        Break 
    }

    ForEach($entry in $FolderNameList){
        Try{
        
            # Create a new folder 
            $folderName = $entry.name
            $useralias = $entry.EmailAddress

            Add-PnPFolder -Name $folderName -Folder $ListName
            
            # Copy file from current location to the SharePoint Folder 
            $file = Add-PNPFile -Path "C:\temp\CreateSharePointFolders.log" -Folder "$ListName\$folderName"

            # Create a child folder of this new parent folder. 
            $Child = "ChildLevel1"
            Add-PnPFolder -Name $Child -Folder "$ListName\$folderName"

            # Create a child folder of this new child folder. 
            Add-PnPFolder -Name "ChildLevel2" -Folder "$ListName\$folderName\$Child"

            # Get folder properites from list
            $listItem = Get-PnPListItem -List $ListName -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$foldername</Value></Eq></Where></Query></View>"
            $listItem 

            # Set permissions on the folder
            Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias -AddRole $access -ClearExisting
            Set-PnPListItemPermission -List $ListName -Identity $listItem -User $username -RemoveRole $access 
            Write-Host ''
            
            # Log to local file 
            $output = "Successfully Created the folder '$folderName' with user $useralias with access role of '$access'`n"
            $status = "Success"
        }
        Catch{
            $output = "Failed to create the folder '$folderName' with user $useralias with access role of '$access'`n Exception Message: $($_.Exception.Message).`n"
            $status ="Fail"
        }
        Finally{
            Write-Host $output -ForegroundColor Yellow
            Write-Log $output
            Log_ToSplunk -Message $output -Status $status
        }
    }
}

Function Create-StoresFolderAndAddPermission {
    # Get stores number from the network share files list
    $stores = Get-ChildItem -Path "\\SERVER\SHARE\...\Store Targets\" -Name
    $count = 0

    Write-Host "Total count of: $count"

    Foreach($store in $stores){

        $store.Substring(0,4)
        $count++
    }

    Write-Host "`nTotal stores count: $count"

    ForEach($store in $stores){
        $succeeded = $false

        while(!$succeeded)
        {
            if($countFail -eq 5)
            {
                break
            }
            Try{
                # Local variables
                $useralias = "user9admin@example.com"
                $st = "st"  
            
                # Create a new folder 
                $folderName = $store.Substring(0,4)

                if(!(Test-Path "\\$folderName$st\c`$\Reports"))
                {
                    Write-Host "$folderName$st is currently offline"
                    break
                }

                Add-PnPFolder -Name $folderName -Folder $ListName

                # Create 2019 folder 
                Add-PnPFolder -Name "2019" -Folder "$ListName\$folderName"

                # Load everything
                $LocalFolderLocation = "\\$folderName$st\c`$\...\2019"
                $documentLibraryName = "$ListName\$folderName\2019"
                $path = $LocalFolderLocation.TrimEnd('\')

                $file = Get-ChildItem -Path $LocalFolderLocation -Recurse
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                (dir $path -Recurse) | %{
                try{ 
                    $i++
                    if($_.GetType().Name -eq "FileInfo"){
                       $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                       $status = "Uploading Files :'" + $_.Name.SubString(0,4) + "' to Location :" + $SPFolderName

                       Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                       $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                    }        
                }
                catch{ }
                }

                # Create 2018 folder 
                Add-PnPFolder -Name "2018" -Folder "$ListName\$folderName"

                # Load everything
                $st = "st"  
                $LocalFolderLocation = "\\$folderName$st\c`$\...\2018"
                $documentLibraryName = "$ListName\$folderName\2018"
                $path = $LocalFolderLocation.TrimEnd('\')

                $file = Get-ChildItem -Path $LocalFolderLocation -Recurse
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                (dir $path -Recurse) | %{
                try{ 
                    $i++
                    if($_.GetType().Name -eq "FileInfo"){
                       $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                       $status = "Uploading Files :'" + $_.Name.SubString(0,4) + "' to Location :" + $SPFolderName

                       Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                       $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                    }        
                }
                catch{ }
                }

                # Create Dropbox folder 
                if(Test-Path "\\$folderName$st\c`$\...\Dropbox")
                {
                    Add-PnPFolder -Name "Dropbox" -Folder "$ListName\$folderName"

                    # Load everything  
                    $LocalFolderLocation = "\\$folderName$st\c`$\...\Dropbox"
                    $documentLibraryName = "$ListName\$folderName\Dropbox"
                    $path = $LocalFolderLocation.TrimEnd('\')

                    $file = Get-ChildItem -Path $LocalFolderLocation -Recurse
                    $i = 0;
                    Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                    (dir $path -Recurse) | %{
                    try{ 
                        $i++
                        if($_.GetType().Name -eq "FileInfo"){
                        $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                        $status = "Uploading Files :'" + $_.Name.SubString(0,4) + "' to Location :" + $SPFolderName

                        Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                        $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                        }        
                    }
                    catch{ }
                    }
                    
                }

                # Create Manager folder 
                if(Test-Path "\\$folderName$st\c`$\...\Manager")
                {
                    Add-PnPFolder -Name "Manager" -Folder "$ListName\$folderName"

                    # Load everything
                    $st = "st"  
                    $LocalFolderLocation = "\\$folderName$st\c`$\...\Manager"
                    $documentLibraryName = "$ListName\$folderName\Manager"
                    $path = $LocalFolderLocation.TrimEnd('\')

                    $file = Get-ChildItem -Path $LocalFolderLocation -Recurse
                    $i = 0;
                    Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                    (dir $path -Recurse) | %{
                    try{ 
                        $i++
                        if($_.GetType().Name -eq "FileInfo"){
                        $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                        $status = "Uploading Files :'" + $_.Name.SubString(0,4) + "' to Location :" + $SPFolderName

                        Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                        $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                        }        
                    }
                    catch{ }
                    }
                }
                
                # Get folder properites from list
                $listItem = Get-PnPListItem -List $ListName -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$foldername</Value></Eq></Where></Query></View>"
                $listItem 

                # Set permissions on the folder
                Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias -AddRole $access -ClearExisting
                Set-PnPListItemPermission -List $ListName -Identity $listItem -User $username -RemoveRole $access 
                Write-Host ''
                
                # Log to local file 
                $output = "Successfully Created the folder '$folderName' with user $useralias with access role of '$access'`n"
                $status = "Success"

                $succeeded = $true
                $countFail = 0
            }
            Catch{
                $output = "Failed to create the folder '$folderName' with user $useralias with access role of '$access'`n Exception Message: $($_.Exception.Message).`n"
                $status ="Fail"
                Start-Sleep -Seconds 30
                $countFail++
                $succeeded = $false
            }
            Finally{
                Write-Host $output -ForegroundColor Yellow
                Write-Log $output
                Log_ToSplunk -Message $output -Status $status
            }
        }
    }
}

Function Create-StoresFolderAndAddPermissionCSV {
    # Import CSV data for store list to upload 
    $stores = Import-Csv -Path $storeslist

    ForEach($number in $stores){

        $folderName = $number.stores
        Write-Host "Processing UFO_NUMBER: $folderName"

        $st = "st"
        $check = Test-Path "\\$folderName$st\c`$\Reports"
        if($check -eq $false)
        {
            Write-Host "$folderName$st is offline"
        }
        else
        {
            $succeeded = $false

            while(!$succeeded)
            {
                if($countFail -eq 5)
                {
                    break
                }
                Try{
                    # Local variables
                    $useralias = "user9admin@example.com"
                    $st = "st"  

                    Add-PnPFolder -Name $folderName -Folder $ListName

                    # Create 2019 folder 
                    Add-PnPFolder -Name "2019" -Folder "$ListName\$folderName"

                    # Load everything
                    $LocalFolderLocation = "\\$folderName$st\c`$\...\2019"
                    $documentLibraryName = "$ListName\$folderName\2019"
                    $path = $LocalFolderLocation.TrimEnd('\')

                    $file = Get-ChildItem -Path $LocalFolderLocation -Recurse
                    $i = 0;
                    Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                    (dir $path -Recurse) | %{
                    try{ 
                        $i++
                        if($_.GetType().Name -eq "FileInfo"){
                        $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                        $status = "Uploading Files :'" + $_.Name.SubString(0,4) + "' to Location :" + $SPFolderName

                        Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                        $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                        }        
                    }
                    catch{ }
                    }

                    # Create 2018 folder 
                    Add-PnPFolder -Name "2018" -Folder "$ListName\$folderName"

                    # Load everything
                    $st = "st"  
                    $LocalFolderLocation = "\\$folderName$st\c`$\...\2018"
                    $documentLibraryName = "$ListName\$folderName\2018"
                    $path = $LocalFolderLocation.TrimEnd('\')

                    $file = Get-ChildItem -Path $LocalFolderLocation -Recurse
                    $i = 0;
                    Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                    (dir $path -Recurse) | %{
                    try{ 
                        $i++
                        if($_.GetType().Name -eq "FileInfo"){
                        $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                        $status = "Uploading Files :'" + $_.Name.SubString(0,4) + "' to Location :" + $SPFolderName

                        Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                        $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                        }        
                    }
                    catch{ }
                    }

                    # Create Dropbox folder 
                    if(Test-Path "\\$folderName$st\c`$\...\Dropbox")
                    {
                        Add-PnPFolder -Name "Dropbox" -Folder "$ListName\$folderName"

                        # Load everything  
                        $LocalFolderLocation = "\\$folderName$st\c`$\...\Dropbox"
                        $documentLibraryName = "$ListName\$folderName\Dropbox"
                        $path = $LocalFolderLocation.TrimEnd('\')

                        $file = Get-ChildItem -Path $LocalFolderLocation -Recurse
                        $i = 0;
                        Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                        (dir $path -Recurse) | %{
                        try{ 
                            $i++
                            if($_.GetType().Name -eq "FileInfo"){
                            $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                            $status = "Uploading Files :'" + $_.Name.SubString(0,4) + "' to Location :" + $SPFolderName

                            Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                            $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                            }        
                        }
                        catch{ }
                        }
                        
                    }

                    # Create Manager folder 
                    if(Test-Path "\\$folderName$st\c`$\...\Manager")
                    {
                        Add-PnPFolder -Name "Manager" -Folder "$ListName\$folderName"

                        # Load everything
                        $st = "st"  
                        $LocalFolderLocation = "\\$folderName$st\c`$\...\Manager"
                        $documentLibraryName = "$ListName\$folderName\Manager"
                        $path = $LocalFolderLocation.TrimEnd('\')

                        $file = Get-ChildItem -Path $LocalFolderLocation -Recurse
                        $i = 0;
                        Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                        (dir $path -Recurse) | %{
                        try{ 
                            $i++
                            if($_.GetType().Name -eq "FileInfo"){
                            $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                            $status = "Uploading Files :'" + $_.Name.SubString(0,4) + "' to Location :" + $SPFolderName

                            Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                            $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                            }        
                        }
                        catch{ }
                        }
                    }

                    # Get folder properites from list
                    $listItem = Get-PnPListItem -List $ListName -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$foldername</Value></Eq></Where></Query></View>"
                    $listItem 

                    # Set permissions on the folder
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias -AddRole $access -ClearExisting
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $username -RemoveRole $access 
                    Write-Host ''
                    
                    # Log to local file 
                    $output = "Successfully Created the folder '$folderName' with user $useralias with access role of '$access'`n"
                    $status = "Success"

                    $succeeded = $true
                    $countFail = 0
                }
                Catch{
                    $output = "Failed to create the folder '$folderName' with user $useralias with access role of '$access'`n Exception Message: $($_.Exception.Message).`n"
                    $status ="Fail"
                    Start-Sleep -Seconds 30
                    $countFail++
                    $succeeded = $false
                }
                Finally{
                    Write-Host $output -ForegroundColor Yellow
                    Write-Log $output
                    Log_ToSplunk -Message $output -Status $status
                }
            }
        }
    }
}

Function Create-SingleFolderAndAddPermission ($folderName){
    Try{
    Log_ToSplunk -Message "Script Starting." -Type "Informational Begin" -Status "" -ID "$Script:UID"
    # Local variables
    $str = "STR"
    $mgr = "MGR"
    $useralias1 = "$folderName$str@example.com"  
    $useralias2 = "$folderName$mgr@example.com" 

    Add-PnPFolder -Name $folderName -Folder $ListName

    Log_ToSplunk -Message "Start checking store '$folderName' for missing PnL files for year $currentYear" -ID "$Script:UID"
    CopyMissingPnLFiles $folderName $currentYear
    Log_ToSplunk -Message "Completed checking store '$folderName' for missing PnL files for year $currentYear" -ID "$Script:UID"
                    
    Log_ToSplunk -Message "Start checking store '$folderName' for missing critical files for year $previousYear" -ID "$Script:UID"
    Copy-MissingCriticalFiles $folderName $previousYear
    Log_ToSplunk -Message "Completed checking store '$folderName' for missing critical files for year $previousYear" -ID "$Script:UID"
                    
    Log_ToSplunk -Message "Start checking store '$folderName' for missing supplemental files for year $previousYear" -ID "$Script:UID"
    Copy-MissingSupplementalFiles $folderName $previousYear
    Log_ToSplunk -Message "Completed checking store '$folderName' for missing supplemental files for year $previousYear" -ID "$Script:UID"
                    
    Log_ToSplunk -Message "Start checking store '$folderName' for missing critical files for year $currentYear" -ID "$Script:UID"                    
    Copy-MissingCriticalFiles $folderName $currentYear
    Log_ToSplunk -Message "Completed checking store '$folderName' for missing critical files for year $currentYear" -ID "$Script:UID"

    Log_ToSplunk -Message "Start checking store '$folderName' for missing supplemental files for year $currentYear" -ID "$Script:UID"
    Copy-MissingSupplementalFiles $folderName $currentYear
    Log_ToSplunk -Message "Completed checking store '$folderName' for missing supplemental files for year $currentYear" -ID "$Script:UID"

    # Get folder properites from list
    $listItem = Get-PnPListItem -List $ListName -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$foldername</Value></Eq></Where></Query></View>"
    $listItem 

    # Set permissions on the folder
    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias1 -AddRole $access -ClearExisting
    Start-Sleep -Seconds 10
    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias2 -AddRole $access 
    Start-Sleep -Seconds 10
    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $username -RemoveRole "Full Control" 
    Write-Host ''
                    
    # Log to local file 
    $output = "Successfully Created the folder '$folderName' with user $useralias2 with access role of '$access'`n"
    $status = "Success"

    $succeeded = $true
    $countFail = 0
    }
    Catch{
    $output = "Failed to create the folder '$folderName' with user $useralias2 with access role of '$access'`n Exception Message: $($_.Exception.Message).`n"
    $status ="Fail"
    Start-Sleep -Seconds 30
    $countFail++
    $succeeded = $false
    }
    Finally{
    Write-Host $output -ForegroundColor Yellow
    Write-Log $output
    Log_ToSplunk -Message $output -Status $status -ID "$Script:UID"
    Log_ToSplunk -Message "Script Ending." -Type "Informational End" -Status "" -ID "$Script:UID"
    }
}

Function Load-StoresReportFolderAndAddPermission {
    # Get stores number from the network share files list
    $stores = Get-ChildItem -Path "\\SERVER\SHARE\...\Store Targets\" -Name
    $count = 0

    Write-Host "Total count of: $count"

    Foreach($store in $stores){

        $store.Substring(0,4)
        $count++
    }

    Write-Host "`nTotal stores count: $count"

    ForEach($store in $stores){
        $succeeded = $false

        while(!$succeeded)
        {
            if($countFail -eq 5)
            {
                break
            }
            Try{
                # Local variables
                $useralias = "user9admin@example.com"
            
                # Create a new folder 
                $folderName = $store.Substring(0,4)

                Add-PnPFolder -Name $folderName -Folder $ListName

                # Load everything from each store Reports folder to the SharePoint 
                $st = "st"
                $LocalFolderLocation = "\\$folderName$st\c`$\...\"
                $documentLibraryName = "$ListName\$folderName"
                $path = $LocalFolderLocation.TrimEnd('\')

                $file = Get-ChildItem -Path $LocalFolderLocation -Recurse
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                (dir $path -Recurse) | %{
                  try{ 
                      $i++
                if($_.GetType().Name -eq "FileInfo"){
                   $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                   $status = "Uploading Files :'" + $_.Name.SubString(0,4) + "' to Location :" + $SPFolderName
                    Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                }        
                    }
                catch{ }
                }

                # Get folder properites from list
                $listItem = Get-PnPListItem -List $ListName -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$foldername</Value></Eq></Where></Query></View>"
                $listItem 

                # Set permissions on the folder
                Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias -AddRole $access -ClearExisting
                Set-PnPListItemPermission -List $ListName -Identity $listItem -User $username -RemoveRole $access 
                Write-Host ''
                
                # Log to local file 
                $output = "Successfully Created the folder '$folderName' with user $useralias with access role of '$access'`n"
                $status = "Success"

                $succeeded = $true
                $countFail = 0
            }
            Catch{
                $output = "Failed to create the folder '$folderName' with user $useralias with access role of '$access'`n Exception Message: $($_.Exception.Message).`n"
                $status ="Fail"
                Start-Sleep -Seconds 30
                $countFail++
                $succeeded = $false
            }
            Finally{
                Write-Host $output -ForegroundColor Yellow
                Write-Log $output
                Log_ToSplunk -Message $output -Status $status
            }
        }
    }
}

Function Copy-MissingCriticalFiles($folderName,$Year)
{
    Add-PnPFolder -Name $folderName -Folder $ListName

    # Create Year folder 
    Add-PnPFolder -Name $Year -Folder "$ListName\$folderName"

    # Load everything
    Foreach($number in 1..12)
    {
        $name = "P$number"
        Add-PnPFolder -Name "$name" -Folder "$ListName\$folderName\$Year"
        $documentLibraryName = "$ListName\$folderName\$Year\$name"
        $path = "$source$Year\$name"
        $LocalFolderLocation = "$source$Year\$name"

        if($name -eq 'P1')
        {
            Foreach($count in 1..4)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 1..4 loop   
        } # End of if P1 

        if($name -eq 'P2')
        {
            Foreach($count in 5..8)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"
                                    
                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000
            } # End of foreach $count in 5..8 loop     
        } # End of if P2

        # P3 
        if($name -eq 'P3')
        {
            Foreach($count in 9..13)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000
            } # End of foreach $count in 9..13 loop     
        } # End of if P3

        # P4
        if($name -eq 'P4')
        {
            Foreach($count in 14..17)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 14..17 loop     
        } # End of if P4

        # P5
        if($name -eq 'P5')
        {
            Foreach($count in 18..21)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 18..21 loop     
        } # End of if P5

        # P6
        if($name -eq 'P6')
        {
            Foreach($count in 22..26)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 22..26 loop     
        } # End of if P6

        # P7
        if($name -eq 'P7')
        {
            Foreach($count in 27..30)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 27..30 loop     
        } # End of if P7

        # P8
        if($name -eq 'P8')
        {
            Foreach($count in 31..34)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 31..34 loop     
        } # End of if P8

        # P9
        if($name -eq 'P9')
        {
            Foreach($count in 35..39)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 35..39 loop     
        } # End of if P9

        # P10
        if($name -eq 'P10')
        {
            Foreach($count in 40..43)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 40..43 loop     
        } # End of if P10

        # P11
        if($name -eq 'P11')
        {
            Foreach($count in 44..47)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 44..47 loop     
        } # End of if P11

        # P12
        if($name -eq 'P12')
        {
            Foreach($count in 48..52)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Critical"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Critical
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 48..52 loop     
        } # End of if P12
    } # End of $number in 1..12
}

Function Copy-MissingSupplementalFiles($folderName,$Year)
{
    Add-PnPFolder -Name $folderName -Folder $ListName

    # Create 2019 folder 
    Add-PnPFolder -Name $Year -Folder "$ListName\$folderName"

    # Load everything
    Foreach($number in 1..12)
    {
        $name = "P$number"
        Add-PnPFolder -Name "$name" -Folder "$ListName\$folderName\$Year"
        $documentLibraryName = "$ListName\$folderName\$Year\$name"
        $path = "$source$Year\$name"
        $LocalFolderLocation = "$source$Year\$name"

        if($name -eq 'P1')
        {
            Foreach($count in 1..4)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                # Create Supplemental folder 
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"

                # Copy Supplemental files 
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop 

                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 1..4 loop   
        } # End of if P1 

        if($name -eq 'P2')
        {
            Foreach($count in 5..8)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"
                                    
                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop 

                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000
            } # End of foreach $count in 5..8 loop     
        } # End of if P2

        # P3 
        if($name -eq 'P3')
        {
            Foreach($count in 9..13)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop 

                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
                
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000
            } # End of foreach $count in 9..13 loop     
        } # End of if P3

        # P4
        if($name -eq 'P4')
        {
            Foreach($count in 14..17)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 14..17 loop     
        } # End of if P4

        # P5
        if($name -eq 'P5')
        {
            Foreach($count in 18..21)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 18..21 loop     
        } # End of if P5

        # P6
        if($name -eq 'P6')
        {
            Foreach($count in 22..26)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 22..26 loop     
        } # End of if P6

        # P7
        if($name -eq 'P7')
        {
            Foreach($count in 27..30)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 27..30 loop     
        } # End of if P7

        # P8
        if($name -eq 'P8')
        {
            Foreach($count in 31..34)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 31..34 loop     
        } # End of if P8

        # P9
        if($name -eq 'P9')
        {
            Foreach($count in 35..39)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 35..39 loop     
        } # End of if P9

        # P10
        if($name -eq 'P10')
        {
            Foreach($count in 40..43)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 40..43 loop     
        } # End of if P10

        # P11
        if($name -eq 'P11')
        {
            Foreach($count in 44..47)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 44..47 loop     
        } # End of if P11

        # P12
        if($name -eq 'P12')
        {
            Foreach($count in 48..52)
            {
                $currentFolderName = "Wk $count"
                Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
                $currentSubFolderName = "Supplemental"
                Add-PnPFolder -Name $currentSubFolderName -Folder "$ListName\$folderName\$Year\$name\$currentFolderName"
                $path = "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                Write-Host "Current Path to copy files: $path"
                                
                $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
                $i = 0;
                Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
                Foreach($item in $file){
                    Write-Host "Check file $item from the $path" 

                    $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                    $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item"

                    $serverModified = $check.TimeLastModified
                    $localModified = $local.LastWriteTime 

                    Write-Host "Local File Time Stamp: $localModified"
                    Write-Host "Server File Time Stamp: $serverModified"

                    if(($check -eq $null) -or ($serverModified -lt $localModified))
                    {
                        Write-Host "$item does not exist or is outdated. Copy the latest from source."
                        $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                    }
                } # End of foreach $item in $file loop
                
                # Copy OSD Reports files $OSDReports
                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental\OSD Reports\
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Create OSD Reports folder 
                $OSDReports = "OSD Reports"
                Add-PnPFolder -Name $OSDReports -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$OSDReports"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 

                # Copy PDF Files \\SERVER\SHARE\...\Wk 1\Supplemental
                # USA - DOMAIN, Canada - VVS, Australia - SAPL 

                # Add Country specific files 
                $usa = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $aus = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse
                $can = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName" -Recurse

                # Add USA Files 
                if(([int]$folderName -gt 1000) -and ([int]$folderName -lt 2000) -or ([int]$folderName -gt 4000)){
                    Foreach($item in $usa){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\DOMAIN\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $usa
                } # End of if $folderName is within 1000 and 2000 or greater than 4000  

                # Add Canada Files
                if(([int]$folderName -gt 2000) -and ([int]$folderName -lt 3000)){
                    Foreach($item in $can){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\VVS\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $can
                } # End of if $folderName is within 2000 and 3000  

                # Add Australia Files
                if(([int]$folderName -gt 3000) -and ([int]$folderName -lt 4000)){
                    Foreach($item in $aus){
                        Write-Host $item 
                                        
                        $checkPDF = Get-PnPFile -url "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                        $localPDF = Get-ChildItem -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item"
                                        
                        $serverModified = $checkPDF.TimeLastModified
                        $localModified = $localPDF.LastWriteTime 
                        Write-Host "Local File Time Stamp: $localModified"
                        Write-Host "Server File Time Stamp: $serverModified"
                                    
                        if(($checkPDF -eq $null) -or ($serverModified -lt $localModified))
                        {
                            Write-Host "$item does not exist or is outdated. Copy the latest from source."
                            $itemPDF = Add-PNPFile -Path "$sourcePDF\SAPL\$Year\$name\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
                        } # end of if missing or source is newer 
                    } # End of $item in $aus
                } # End of if $folderName is within 3000 and 4000 
            } # End of foreach $count in 48..52 loop     
        } # End of if P12
    } # End of $number in 1..12
}

Function CopyMissingPnLFiles($folderName, $Year) {
    Add-PnPFolder -Name $folderName -Folder $ListName

    # Create year folder 
    Add-PnPFolder -Name $Year -Folder "$ListName\$folderName"

    # Load PnL files for each period from 1 to 12
    Foreach($number in 1..12)
    {
        $name = "P$number"
        Add-PnPFolder -Name "$name" -Folder "$ListName\$folderName\$Year"
        $documentLibraryName = "$ListName\$folderName\$Year\$name"
        $path = "$source$Year\$name"
        $LocalFolderLocation = "$source$Year\$name"

        $currentFolderName = "PnL"
        Add-PnPFolder -Name $currentFolderName -Folder "$ListName\$folderName\$Year\$name"
  
        # Copy PnL files 
        $path = "$ListName\$folderName\$Year\$name\$currentFolderName"

        Write-Host "Current Path to copy files: $path"
                                
        $file = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName" -Recurse | Where-Object {$_.Name.SubString(0,4) -match $folderName}
        $i = 0;
        Write-Host "Uploading documents to Site $folderName" -ForegroundColor Cyan 
                                
        Foreach($item in $file){
            Write-Host "Check file $item from the $path" 

            $check = Get-PnPFile -Url "$ListName\$folderName\$Year\$name\$currentFolderName\$item"
            $local = Get-ChildItem -Path "$LocalFolderLocation\$currentFolderName\$item"

            $serverModified = $check.TimeLastModified
            $localModified = $local.LastWriteTime 

            Write-Host "Local File Time Stamp: $localModified"
            Write-Host "Server File Time Stamp: $serverModified"

            if(($check -eq $null) -or ($serverModified -lt $localModified))
            {
                Write-Host "$item does not exist or is outdated. Copy the latest from source."
                $itemXLS = Add-PNPFile -Path "$LocalFolderLocation\$currentFolderName\$currentSubFolderName\$item" -Folder "$ListName\$folderName\$Year\$name\$currentFolderName\$currentSubFolderName"
            }
        } # End of foreach $item in $file loop 
    } # End of Load PnL files for each period from 1 to 12
}

Function Create-CopyMissingFilesCSV {
    # Import CSV data for store list to upload 
    $stores = Import-Csv -Path $storeslist
    $source = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution\"
    $sourcePDF = "\\SERVER\SHARE\...\REPORTS" # \\SERVER\SHARE\...\Wk 1\Critical
    $previousYear = (Get-Date -Format yyyy) - 1 
    $currentYear = Get-Date -Format yyyy
    $sourcePreviousYear = $source + $previousYear 
    $sourceCurrentYear = $source + $currentYear

    ForEach($number in $stores){

        # $number.stores = "1174" # To be removed later after testing 
        # USA 1174, Canada 2001, Australia 3001

        $folderName = $number.stores
        Write-Host "Processing UFO_NUMBER: $folderName"

        $check = Test-Path $sourceCurrentYear
        if($check -eq $false)
        {
            Write-Host "$source is offline or this account does not have permission to connect to it."
        }
        else
        {
            $succeeded = $false

            while(!$succeeded)
            {
                if($countFail -eq 5)
                {
                    break
                }
                Try{
                    # Log_ToSplunk -Message "Script Starting." -Type "Informational Begin" -Status "" -ID "$Script:UID"
                    # Local variables
                    $str = "STR"
                    $mgr = "MGR"
                    $useralias1 = "$folderName$str@example.com"  
                    $useralias2 = "$folderName$mgr@example.com" 

                    Add-PnPFolder -Name $folderName -Folder $ListName

                    # Log_ToSplunk -Message "Start checking store '$folderName' for missing PnL files for year $currentYear" -ID "$Script:UID"
                    CopyMissingPnLFiles $folderName $currentYear
                    CopyMissingPnLFiles $folderName $previousYear 
                    # Log_ToSplunk -Message "Completed checking store '$folderName' for missing PnL files for year $currentYear" -ID "$Script:UID"
                    
                    # Log_ToSplunk -Message "Start checking store '$folderName' for missing critical files for year $previousYear" -ID "$Script:UID"
                    Copy-MissingCriticalFiles $folderName $previousYear
                    # Log_ToSplunk -Message "Completed checking store '$folderName' for missing critical files for year $previousYear" -ID "$Script:UID"
                    
                    # Log_ToSplunk -Message "Start checking store '$folderName' for missing supplemental files for year $previousYear" -ID "$Script:UID"
                    Copy-MissingSupplementalFiles $folderName $previousYear
                    # Log_ToSplunk -Message "Completed checking store '$folderName' for missing supplemental files for year $previousYear" -ID "$Script:UID"
                    
                    # Log_ToSplunk -Message "Start checking store '$folderName' for missing critical files for year $currentYear" -ID "$Script:UID"                    
                    Copy-MissingCriticalFiles $folderName $currentYear
                    # Log_ToSplunk -Message "Completed checking store '$folderName' for missing critical files for year $currentYear" -ID "$Script:UID"

                    # Log_ToSplunk -Message "Start checking store '$folderName' for missing supplemental files for year $currentYear" -ID "$Script:UID"
                    Copy-MissingSupplementalFiles $folderName $currentYear
                    # Log_ToSplunk -Message "Completed checking store '$folderName' for missing supplemental files for year $currentYear" -ID "$Script:UID"

                    # Get folder properites from list
                    $listItem = Get-PnPListItem -List $ListName -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$foldername</Value></Eq></Where></Query></View>"
                    $listItem 

                    # Set permissions on the folder
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias1 -AddRole $access -ClearExisting
                    Start-Sleep -Seconds 10
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias2 -AddRole $access 
                    Start-Sleep -Seconds 10
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $username -RemoveRole "Full Control" 
                    Write-Host ''
                    
                    # Log to local file 
                    $output = "Successfully Created the folder '$folderName' with user $useralias2 with access role of '$access'`n"
                    $status = "Success"

                    $succeeded = $true
                    $countFail = 0
                }
                Catch{
                    $output = "Failed to create the folder '$folderName' with user $useralias2 with access role of '$access'`n Exception Message: $($_.Exception.Message).`n"
                    $status ="Fail"
                    Start-Sleep -Seconds 30
                    $countFail++
                    $succeeded = $false
                }
                Finally{
                    Write-Host $output -ForegroundColor Yellow
                    Write-Log $output
                    # Log_ToSplunk -Message $output -Status $status -ID "$Script:UID"
                    # Log_ToSplunk -Message "Script Ending." -Type "Informational End" -Status "" -ID "$Script:UID"
                }
            }
        }
    }
}

Function Create-CopyMissingFilesAD {
    # Search Active Directory for store computer list to upload 
    $OU = "OU=Store Computers,OU=Store Computers,DC=DOMAIN,DC=com"
    $computers = Get-ADComputer -Filter "Name -like '*st'" -SearchBase $($OU) | Sort-Object

    $source = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution\"
    $sourcePDF = "\\SERVER\SHARE\...\REPORTS" # \\SERVER\SHARE\...\Wk 1\Critical
    $previousYear = (Get-Date -Format yyyy) - 1 
    $currentYear = Get-Date -Format yyyy
    $sourcePreviousYear = $source + $previousYear 
    $sourceCurrentYear = $source + $currentYear

    ForEach($computer in $computers){

        $folderName = $computer.name.Substring(0,4)
        Write-Host "Processing UFO_NUMBER: $folderName"
        
        <#
        $st = "st"
        IF(Test-Path "\\$folderName$st\c`$\...\")
        {
            Write-Host "$folderName is live"
        }
        Else
        {
            Write-Host "$folderName is offline"
            continue
        }
        #>
        $check = Test-Path $sourceCurrentYear
        if($check -eq $false)
        {
            Write-Host "$source is offline or this account does not have permission to connect to it."
        }
        else
        {
            $succeeded = $false

            while(!$succeeded)
            {
                if($countFail -eq 5)
                {
                    break
                }
                Try{
                    Log_ToSplunk -Message "Script Starting." -Type "Informational Begin" -Status "" -ID "$Script:UID"
                    # Local variables
                    $str = "STR"
                    $mgr = "MGR"
                    $useralias1 = "$folderName$str@example.com"  
                    $useralias2 = "$folderName$mgr@example.com" 

                    Add-PnPFolder -Name $folderName -Folder $ListName

                    Log_ToSplunk -Message "Start checking store '$folderName' for missing PnL files for year $currentYear" -ID "$Script:UID"
                    CopyMissingPnLFiles $folderName $currentYear
                    Log_ToSplunk -Message "Completed checking store '$folderName' for missing PnL files for year $currentYear" -ID "$Script:UID"
                    
                    Log_ToSplunk -Message "Start checking store '$folderName' for missing critical files for year $previousYear" -ID "$Script:UID"
                    Copy-MissingCriticalFiles $folderName $previousYear
                    Log_ToSplunk -Message "Completed checking store '$folderName' for missing critical files for year $previousYear" -ID "$Script:UID"
                    
                    Log_ToSplunk -Message "Start checking store '$folderName' for missing supplemental files for year $previousYear" -ID "$Script:UID"
                    Copy-MissingSupplementalFiles $folderName $previousYear
                    Log_ToSplunk -Message "Completed checking store '$folderName' for missing supplemental files for year $previousYear" -ID "$Script:UID"
                    
                    Log_ToSplunk -Message "Start checking store '$folderName' for missing critical files for year $currentYear" -ID "$Script:UID"                    
                    Copy-MissingCriticalFiles $folderName $currentYear
                    Log_ToSplunk -Message "Completed checking store '$folderName' for missing critical files for year $currentYear" -ID "$Script:UID"

                    Log_ToSplunk -Message "Start checking store '$folderName' for missing supplemental files for year $currentYear" -ID "$Script:UID"
                    Copy-MissingSupplementalFiles $folderName $currentYear
                    Log_ToSplunk -Message "Completed checking store '$folderName' for missing supplemental files for year $currentYear" -ID "$Script:UID"

                    # Get folder properites from list
                    $listItem = Get-PnPListItem -List $ListName -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$foldername</Value></Eq></Where></Query></View>"
                    $listItem 

                    # Set permissions on the folder
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias1 -AddRole $access -ClearExisting
                    Start-Sleep -Seconds 10
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias2 -AddRole $access 
                    Start-Sleep -Seconds 10
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $username -RemoveRole "Full Control" 
                    Write-Host ''
                    
                    # Log to local file 
                    $output = "Successfully Created the folder '$folderName' with user $useralias2 with access role of '$access'`n"
                    $status = "Success"

                    $succeeded = $true
                    $countFail = 0
                }
                Catch{
                    $output = "Failed to create the folder '$folderName' with user $useralias2 with access role of '$access'`n Exception Message: $($_.Exception.Message).`n"
                    $status ="Fail"
                    Start-Sleep -Seconds 30
                    $countFail++
                    $succeeded = $false
                }
                Finally{
                    Write-Host $output -ForegroundColor Yellow
                    Write-Log $output
                    Log_ToSplunk -Message $output -Status $status -ID "$Script:UID"
                    Log_ToSplunk -Message "Script Ending." -Type "Informational End" -Status "" -ID "$Script:UID"
                }
            }
        }
    }
}

Function Create-CopyMissingFilesExistingFile {
    # Local Variables 
    $source = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution\"
    $sourcePDF = "\\SERVER\SHARE\...\REPORTS" # \\SERVER\SHARE\...\Wk 1\Critical
    $previousYear = (Get-Date -Format yyyy) - 1 
    $currentYear = Get-Date -Format yyyy
    $sourcePreviousYear = $source + $previousYear 
    $sourceCurrentYear = $source + $currentYear

    # Search existing files created for the store to replicate 
    $computers = Split-Path -Path "$sourceCurrentYear\P1\Wk 1\Critical\*.xlsx" -Leaf -Resolve

    ForEach($computer in $computers){

        $folderName = $computer.Substring(0,4)
        Write-Host "Processing UFO_NUMBER: $folderName"

        $check = Test-Path $sourceCurrentYear
        if($check -eq $false)
        {
            Write-Host "$source is offline or this account does not have permission to connect to it."
        }
        else
        {
            $succeeded = $false

            while(!$succeeded)
            {
                if($countFail -eq 5)
                {
                    break
                }
                Try{
                    # Log_ToSplunk -Message "Script Starting." -Type "Informational Begin" -Status "" -ID "$Script:UID"
                    # Local variables
                    $str = "STR"
                    $mgr = "MGR"
                    $useralias1 = "$folderName$str@example.com"  
                    $useralias2 = "$folderName$mgr@example.com" 

                    Add-PnPFolder -Name $folderName -Folder $ListName

                    # Log_ToSplunk -Message "Start checking store '$folderName' for missing PnL files for year $currentYear" -ID "$Script:UID"
                    CopyMissingPnLFiles $folderName $currentYear
                    # Log_ToSplunk -Message "Completed checking store '$folderName' for missing PnL files for year $currentYear" -ID "$Script:UID"
                    
                    # Log_ToSplunk -Message "Start checking store '$folderName' for missing critical files for year $previousYear" -ID "$Script:UID"
                    Copy-MissingCriticalFiles $folderName $previousYear
                    # Log_ToSplunk -Message "Completed checking store '$folderName' for missing critical files for year $previousYear" -ID "$Script:UID"
                    
                    # Log_ToSplunk -Message "Start checking store '$folderName' for missing supplemental files for year $previousYear" -ID "$Script:UID"
                    Copy-MissingSupplementalFiles $folderName $previousYear
                    # Log_ToSplunk -Message "Completed checking store '$folderName' for missing supplemental files for year $previousYear" -ID "$Script:UID"
                    
                    # Log_ToSplunk -Message "Start checking store '$folderName' for missing critical files for year $currentYear" -ID "$Script:UID"                    
                    Copy-MissingCriticalFiles $folderName $currentYear
                    # Log_ToSplunk -Message "Completed checking store '$folderName' for missing critical files for year $currentYear" -ID "$Script:UID"

                    # Log_ToSplunk -Message "Start checking store '$folderName' for missing supplemental files for year $currentYear" -ID "$Script:UID"
                    Copy-MissingSupplementalFiles $folderName $currentYear
                    # Log_ToSplunk -Message "Completed checking store '$folderName' for missing supplemental files for year $currentYear" -ID "$Script:UID"

                    # Get folder properites from list
                    $listItem = Get-PnPListItem -List $ListName -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$foldername</Value></Eq></Where></Query></View>"
                    $listItem 

                    # Set permissions on the folder
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias1 -AddRole $access -ClearExisting
                    Start-Sleep -Seconds 10
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $useralias2 -AddRole $access 
                    Start-Sleep -Seconds 10
                    Set-PnPListItemPermission -List $ListName -Identity $listItem -User $username -RemoveRole "Full Control" 
                    Write-Host ''
                    
                    # Log to local file 
                    $output = "Successfully Created the folder '$folderName' with user $useralias2 with access role of '$access'`n"
                    $status = "Success"

                    $succeeded = $true
                    $countFail = 0
                }
                Catch{
                    $output = "Failed to create the folder '$folderName' with user $useralias2 with access role of '$access'`n Exception Message: $($_.Exception.Message).`n"
                    $status ="Fail"
                    Start-Sleep -Seconds 30
                    $countFail++
                    $succeeded = $false
                }
                Finally{
                    Write-Host $output -ForegroundColor Yellow
                    Write-Log $output
                    # Log_ToSplunk -Message $output -Status $status -ID "$Script:UID"
                    # Log_ToSplunk -Message "Script Ending." -Type "Informational End" -Status "" -ID "$Script:UID"
                }
            }
        }
    }
}

# Script Start
Connect-SharePoint

# Create-FolderAndAddPermission 
# Create-StoresFolderAndAddPermission
# Create-StoresFolderAndAddPermissionCSV # Requires C:\Temp\storeslist.csv file 
# Create-SingleFolderAndAddPermission $folderName
Create-CopyMissingFilesCSV
# Create-CopyMissingFilesAD
# Create-CopyMissingFilesExistingFile

# Script End
