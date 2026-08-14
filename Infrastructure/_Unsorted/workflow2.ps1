workflow test-workflow2 {
    $source = "\\SERVER\SHARE\...\" # Dropbox source location 
    $currentYear = Get-Date -Format yyyy
    $sourceCurrentYear = $source + $currentYear
    
    $sourcePath = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution"
    $computers = Split-Path -Path "$sourcePath\$currentYear\P1\Wk 1\Critical\*.xlsx" -Leaf -Resolve

    ForEach -parallel ($computer in $computers){
        # Check-RunAsAdministrator
        # Connect-SharePoint
        $folderName = $computer.Substring(0,4)
        $folderName
            
    } # -ThrottleLimit 5
}
test-workflow2