        #Connect to PnP Online
        $username = "svc_ReportCenterSync@example.com"
        $password = "<password>"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
        Connect-PnPOnline -Url $SiteURL -Credentials $cred #-UseWebLogin 
 
        #Get the Target Folder to Upload
        $Web = Get-PnPWeb
        $List = Get-PnPList $LibraryName -Includes RootFolder
        $TargetFolder = $List.RootFolder
        $TargetFolderSiteRelativeURL = $TargetFolder.ServerRelativeURL.Replace($Web.ServerRelativeUrl,"")
  
        #Get All Items from the Source
        $Source = Get-ChildItem -Path $SourceFolderPath -Recurse
        $SourceItems = $Source | Select FullName, PSIsContainer, @{Label='TargetItemURL';Expression={$_.FullName.Replace($SourceFolderPath,$TargetFolderSiteRelativeURL).Replace("\","/")}}
        Add-content $Logfile -value "Number of Items Found in the Source: $($SourceItems.Count)"
  
        #Upload Source Items from Fileshare to Target SharePoint Online document library
        $Counter = 1
        $SourceItems | ForEach-Object {
                #Calculate Target Folder URL
                $TargetFolderURL = (Split-Path $_.TargetItemURL -Parent).Replace("\","/")
                $ItemName = Split-Path $_.FullName -leaf
                    
                #Replace Invalid Characters
                $ItemName = [RegEx]::Replace($ItemName, "[{0}]" -f ([RegEx]::Escape([String]'\"*:<>?/\|')), '_')
 
                #Display Progress bar
                $Status  = "uploading '" + $ItemName + "' to " + $TargetFolderURL +" ($($Counter) of $($SourceItems.Count))"
                Write-Progress -Activity "Uploading ..." -Status $Status -PercentComplete (($Counter / $SourceItems.Count) * 100)
                }