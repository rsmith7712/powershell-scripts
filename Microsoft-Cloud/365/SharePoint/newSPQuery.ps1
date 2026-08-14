# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    newSPQuery.ps1

.DESCRIPTION
    Ensures the PnP.PowerShell module is installed, then connects as a global administrator and queries and logs a SharePoint site tree with transcript logging.

.FUNCTIONALITY
    Queries a SharePoint Online site tree via PnP.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Ensure PnP.PowerShell is installed and import it
if (-not (Get-Module -ListAvailable -Name "PnP.PowerShell")) {
    Write-Output "PnP.PowerShell module not found. Installing..."
    Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force -AllowClobber
}
Import-Module PnP.PowerShell

# Start detailed transcript logging
Start-Transcript -Path "C:\temp\sharePointTreeLog.txt" -Append

# Set the Global Administrator username (for display/reference)
$username = "admin-user@domain.co"
Write-Output "Using username: $username"

# Define the tenant admin URL
$tenantAdminUrl = "https://domainaudio-admin.sharepoint.com"
Write-Output "Connecting to SharePoint tenant: $tenantAdminUrl"

# Connect to the SharePoint Admin Center using PnP PowerShell with interactive modern authentication
try {
    Connect-PnPOnline -Url $tenantAdminUrl -Interactive -ErrorAction Stop
    Write-Output "Connected to SharePoint Admin Center successfully."
}
catch {
    Write-Output "Error connecting to SharePoint Admin Center: $_"
    Stop-Transcript
    exit
}

# Retrieve all SharePoint sites using PnP PowerShell (Get-PnPTenantSite)
Write-Output "Retrieving all SharePoint sites..."
try {
    $sites = Get-PnPTenantSite -Detailed -ErrorAction Stop
    Write-Output "Total sites retrieved: $($sites.Count)"
}
catch {
    Write-Output "Error retrieving tenant sites: $_"
    Stop-Transcript
    exit
}

# Initialize a collection to store the detailed site tree information
$result = @()

# Loop through each SharePoint site
foreach ($site in $sites) {
    Write-Output "Processing site: $($site.Url)"

    # Connect to the individual site using interactive authentication.
    # Note: With -Interactive, you'll be prompted for credentials once per site.
    try {
        Connect-PnPOnline -Url $site.Url -Interactive -ErrorAction Stop
        Write-Output "Connected to site: $($site.Url)"
    }
    catch {
        Write-Output "Failed to connect to site: $($site.Url). Error: $_"
        continue
    }
    
    # Retrieve subsites recursively (if any)
    try {
        $subwebs = Get-PnPSubWeb -Recurse -ErrorAction Stop
        Write-Output "Found $($subwebs.Count) subsites for site: $($site.Url)"
    }
    catch {
        Write-Output "No subsites found or error retrieving subsites for site: $($site.Url)"
        $subwebs = @()
    }
    
    # Retrieve pages from the "Site Pages" library (modern pages)
    try {
        $pages = Get-PnPListItem -List "Site Pages" -ErrorAction Stop
        Write-Output "Found $($pages.Count) pages in Site Pages library for site: $($site.Url)"
    }
    catch {
        Write-Output "No pages found or error retrieving pages in Site Pages library for site: $($site.Url)"
        $pages = @()
    }
    
    # Placeholder for channels (actual channel info would require Graph API calls)
    $channels = @("N/A")
    
    # Retrieve Site Collection Administrators (considered as Site Admins)
    try {
        $siteAdmins = Get-PnPSiteCollectionAdmin -ErrorAction Stop
        Write-Output "Retrieved site collection administrators for site: $($site.Url)"
    }
    catch {
        Write-Output "Error retrieving site collection admins for site: $($site.Url)."
        $siteAdmins = @()
    }
    
    # Retrieve SharePoint Groups to extract group owners (which may indicate Site Owners)
    try {
        $groups = Get-PnPGroup -ErrorAction Stop
        $groupOwners = $groups | Where-Object { $_.OwnerTitle -and $_.Title -match "Owner" }
        Write-Output "Retrieved groups for site: $($site.Url)"
    }
    catch {
        Write-Output "Error retrieving groups for site: $($site.Url)."
        $groupOwners = @()
    }
    
    # Build a custom object for the main site
    $result += [PSCustomObject]@{
        SiteUrl     = $site.Url
        Title       = $site.Title
        ItemType    = "Site"
        ChildItem   = ""
        Detail      = ""
        Channel     = ""
        SiteAdmins  = ($siteAdmins | ForEach-Object { $_.LoginName }) -join "; "
        GroupOwners = ($groupOwners | ForEach-Object { $_.Title }) -join "; "
    }
    
    # Add each subsite as a separate record
    foreach ($sub in $subwebs) {
        $result += [PSCustomObject]@{
            SiteUrl     = $site.Url
            Title       = $sub.Title
            ItemType    = "Subsite"
            ChildItem   = $sub.Url
            Detail      = ""
            Channel     = ""
            SiteAdmins  = ($siteAdmins | ForEach-Object { $_.LoginName }) -join "; "
            GroupOwners = ($groupOwners | ForEach-Object { $_.Title }) -join "; "
        }
    }
    
    # Add each page from the "Site Pages" library as a separate record
    foreach ($page in $pages) {
        $result += [PSCustomObject]@{
            SiteUrl     = $site.Url
            Title       = $page.FieldValues["FileLeafRef"]
            ItemType    = "Page"
            ChildItem   = ""
            Detail      = $page.FieldValues["FileRef"]
            Channel     = ""
            SiteAdmins  = ($siteAdmins | ForEach-Object { $_.LoginName }) -join "; "
            GroupOwners = ($groupOwners | ForEach-Object { $_.Title }) -join "; "
        }
    }
    
    # Add channel information as a record (placeholder)
    foreach ($channel in $channels) {
        $result += [PSCustomObject]@{
            SiteUrl     = $site.Url
            Title       = "Channel Info"
            ItemType    = "Channel"
            ChildItem   = ""
            Detail      = ""
            Channel     = $channel
            SiteAdmins  = ($siteAdmins | ForEach-Object { $_.LoginName }) -join "; "
            GroupOwners = ($groupOwners | ForEach-Object { $_.Title }) -join "; "
        }
    }
    
    # Optionally, disconnect from the current site session
    Disconnect-PnPOnline
}

# Ensure the output directory exists
$outputDir = "C:\temp"
if (!(Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

# Export the collected data to CSV
Write-Output "Exporting collected data to CSV file..."
$result | Export-Csv -Path "C:\temp\sharePointSitesTree.csv" -NoTypeInformation -Encoding UTF8
Write-Output "CSV export completed: C:\temp\sharePointSitesTree.csv"

# End transcript logging
Stop-Transcript

Write-Output "Script completed successfully."
