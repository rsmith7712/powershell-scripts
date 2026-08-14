<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: __TEMPLATE__.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Variables

$shortcut = "\\SERVER\SHARE\...\Toggle Proxy Settings.lnk"
$vbs = "\\SERVER\SHARE\...\toggle.proxy.vbs"

# ----------------------------------------------------------------------------------------------
# Script

Copy-Item -Path $shortcut -Destination "C:\Users\Public\Desktop\Toggle Proxy Settings.lnk" -Force
Copy-Item -Path $vbs -Destination "C:\windows\System32\toggle.proxy.vbs" -Force
