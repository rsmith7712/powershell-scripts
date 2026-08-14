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
    Team_Process-SPOListItems.ps1

.SYNOPSIS
  Script connects to a SharePoint Online list and exports the data to a .CSV file for on premesis consumption 
 
.DESCRIPTION
  The SharePoint Online Client Components SDK must be installed on the host executing this script: 
  https://www.microsoft.com/en-us/download/details.aspx?id=42038

.EXAMPLE
  If this script can be called from the command line, show exampls here
  
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  03/29/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (03/29/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    The SharePoint Online Client Components SDK must be installed on the host executing this script:
      https://www.microsoft.com/en-us/download/details.aspx?id=42038

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

$Script:ProductName = "Process-SPOListItems " #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "Inquire" #Maybe change to "SilentlyContinue" for Production.

# Import the required SharePoint Client DLL
Import-Module 'C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll'

# Output CSV file
$outfile = "c:\temp\SPOUsers.csv"
if(Test-Path $outfile){Remove-Item $outfile}

# SPO site URL, subsite name, and targeted list name
$site = 'https://domain.sharepoint.com/sites/TheA-Team'
$subsite = 'SDApps'
$listname = 'Domain New User'


# Get the Client Context and Bind the SPO Site Collection
$context = New-Object Microsoft.SharePoint.Client.ClientContext($site)

# Authenticate SPO User account
$username = "svc_UsrMgmt@example.com"
$password = ConvertTo-SecureString -AsPlainText -Force -String "<password>"
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username,$password)
$context.Credentials = $credentials

$web = $context.Site.OpenWeb($subsite)
$context.Load($web)
$context.ExecuteQuery()

# Connect to the SPO list
$list = $web.Lists.GetByTitle($listname)
$context.Load($list)
$listItems = $list.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
$context.load($listItems)
$context.ExecuteQuery()

# Functions
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
<#
function Log_ToSplunk
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
#>
# ----------------------------------------------------------------------------------------------

# Determine if new user SamAccountName already exists in AD and increment value by 1 as needed
Function Set-SamAccountName{
  Param(
  [Parameter(Mandatory=$true)]
  [string]$samid
  )
  $script:SamAccountName = $samid
      $defaultname =$script:SamAccountName
      $Exit = 0
      $Count = 1

      Do{
          Try{
              # Attempt to retrieve information on the user.
              $User = Get-ADUser -Identity $script:SamAccountName

              # The user exists.
          $script:SamAccountName = $script:SamAccountName
          $script:SamAccountName = $defaultname + $Count++

                  If ($Count -gt 20) {$Exit = 1}
          }
          Catch{
              # User does not exist.
              $Exit = 1
          }
      }
      While ($Exit -eq 0)
}

# Script Starts
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
<#
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"
#>
# Enumerate SPOlist items
foreach($listItem in $listItems){

  if($listItem["Processed"] -eq $false){
      $samid = $listItem["UserName"] 
      Set-SamAccountName $samid

  Write-Host $listItem["FirstName"] $listItem["LastName"] -ForegroundColor Yellow

#       $listItem["Processed"] = $true 
      $listItem["SamAccountName"] = $script:SamAccountName
      $listItem.Update() 
      $context.ExecuteQuery()

      # Export SPO user list items to .CSV file
      $userproperties = [ordered]@{
          ID=$listItem["ID"]
          UserName=$listItem["SamAccountName"]
          FirstName=$listItem["FirstName"]
          LastName=$listItem["LastName"]
          OU=$listItem["OU"]
          Processed=$listItem["Processed"]
          UserType=$listItem["UserType"]
          Title=$listItem["Title"]
          Department=$listItem["Department"]
          Manager=$listItem["Manager"].Email
          Location=$listItem["Location"]
          Country=$listItem["Country"]
          CopyGroupsFrom=$listItem["CopyGroupsFrom"].Email
          CreatedBy=$listItem["Created_x0020_By"].Email
      }

      $objectlist = New-Object -TypeName PSObject -Property $userproperties -ErrorAction SilentlyContinue
      $objectlist | Export-Csv -Path $outfile -Append -NoTypeInformation
      $listItem["Processed"] = $true
      $listItem.Update() 
      $context.ExecuteQuery()

  }   
}

# For testing purposes only
<#
Try{
  Invoke-Item $outfile -ErrorAction Stop
}
  Catch{ 
      Write-Host "$outfile not found." -ForegroundColor Yellow
      Write-Host "Likely cause: All Sharepoint list items have 'Processed' attribute set to 'True'" -ForegroundColor Yellow
  }
  #>

# Script Ends
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
<#
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
#>
Exit