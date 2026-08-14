# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Set-MSOLStatus.ps1

.SYNOPSIS
  Script connects to a SharePoint Online list and writes O365 User account and licensing status to the 'Status' column in the respective list.
 
.DESCRIPTION
  The SharePoint Online Client Components SDK must be installed on the host executing this script: 
  https://www.microsoft.com/en-us/download/details.aspx?id=42038

  
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  05/15/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (05/15/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    The SharePoint Online Client Components SDK must be installed on the host executing this script:
      https://www.microsoft.com/en-us/download/details.aspx?id=42038

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

$Script:ProductName = "Send-MSOLStatus"
$ErrorActionPreference = "SilentlyContinue"

# Functions
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Function Log_ToSplunk
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
 Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}
# -----------------------------------------------------------------------------------------------------------------------
Function Set-MSOLStatus
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        [string]$site,

        [parameter(Mandatory=$true,
        Position=1)]
        $subsite,

        [parameter(Mandatory=$true,
        Position=2)]
        $listname,

        [parameter(Mandatory=$true,
        Position=3)]
        $username
    )
    # Import the required SharePoint Client DLL
        Import-Module 'C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll'

        $context = New-Object Microsoft.SharePoint.Client.ClientContext($site)
 
    # Authentication
        $MSOLCred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username,$password
        $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username,$password)
        $context.Credentials = $credentials

    # Connect to MS Online
    Connect-MsolService -Credential $MSOLCred        

    # Connect to the SPO list
        $web = $context.Site.OpenWeb($subsite)
        $context.Load($web)
        $context.ExecuteQuery()
        $list = $web.Lists.GetByTitle($listname)
        $context.Load($list)
        $listItems = $list.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
        $context.load($listItems)
        $context.ExecuteQuery()
    
    # Update MSOL License status column on SPO List
    foreach($listItem in $listItems){
        $SamAccountname = $listItem["SamAccountName"]
        $upn = $SamAccountname+"@example.com"

        Try{
            $ErrorActionPreference = "Stop"
            Get-MsolUser -UserPrincipalName $upn
                If((Get-MsolUser -UserPrincipalName $upn).IsLicensed -eq $True){
                    $MSOLLicense = "O365 Account - Created and LICENSED"
                    }
                Else{
                    $MSOLLicense = "O365 Account - Created, but NOT LICENSED"
                    }
            }
            Catch{
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Host "ERROR: $ErrorMessage $FailedItem"
                $MSOLLicense = "ERROR:O365-Account creation FAILED, $ErrorMessage $FailedItem"
                }
                Finally{
                        $ErrorActionPreference = "Continue"
                        }
    
        $listItem["Status"] = "$MSOLLicense"
        $listItem.Update() 
        $context.ExecuteQuery()
        }
}
# Script Starts
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

        $site = 'https://domain.sharepoint.com/sites/TheA-Team'
        $subsite = 'SDApps'
        $listname = 'Domain New User'
        $username = "svc_UsrMgmt@example.com"
        $password = ConvertTo-SecureString -AsPlainText -Force -String "<password>"

    Set-MSOLStatus -site $site -subsite $subsite -listname $listname -username $username

# Script Ends
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit
