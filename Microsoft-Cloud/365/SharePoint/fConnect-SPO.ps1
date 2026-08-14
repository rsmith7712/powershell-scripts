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
    fConnect-SPO.ps1

.DESCRIPTION
    Connects to the SharePoint Online Report Center site using the automation service account and the PnP module.

.FUNCTIONALITY
    Establishes a SharePoint Online (PnP) connection.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#$spourl = "https://domain.sharepoint.com/sites/TheA-Team"
$spourl = "https://domain.sharepoint.com/sites/ReportCenter"
$username = "flowautomation@example.com"
$password = "<password>"
$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)

            Try
            {
                $moduleversion = (Import-Module "SharePointPnPPowerShellOnline" -PassThru -Force).Version
                $status = "[SUCCESS] : PS module 'SharePointPnPPowerShellOnline' version: $moduleversion imported successfully.";$color = "green"
            }
                Catch
                {
                    $status = "[WARNING] : Failed to import PS module 'SharePointPnPPowerShellOnline.' Attemping to install module. The following exception occurred: $($_.Exception.Message).";$color = "yellow"
                    # Install required SharePoint PnP Module 
                    Install-Module SharePointPnPPowerShellOnline -Force
                }#-------------------------[END Try/Catch]-----------------------------------------
            Finally
            {
                Write-Host $status -ForegroundColor $color
            }
            Try
            {
                $spConnection = Connect-PnPOnline -Url $spourl -Credentials $cred
                $status = "[SUCCESS] : Connection to SharePoint Online Successfully established";$color = "green"
            }
                Catch
                {
                    $status = "[ERROR] : Failed to connect to $($spourl) as $($username). The following exception occurred: $($_.Exception.Message).";$color = "red"
                }#-------------------------[END Try/Catch]-----------------------------------------
            Finally
            {
                Write-Host $status -ForegroundColor $color
            }

Get-PnPList -Identity 'StoreReports2'|Get-PnPListItem -Fields 'Title'