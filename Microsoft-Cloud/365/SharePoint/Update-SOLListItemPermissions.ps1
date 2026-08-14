# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Update-SOLListItemPermissions.ps1

.SYNOPSIS
 Update-SOLListItemPermissions.ps1
 
.DESCRIPTION
 Update-SOLListItemPermissions.ps1

 Read more: http://www.sharepointdiary.com/2017/11/sharepoint-online-grant-permission-to-list-item-using-powershell.html#ixzz5Uh1cYKA2

.EXAMPLE
  
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  10/24/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 (10/24/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Update-SOLListItemPermissions.ps1

     Read more: http://www.sharepointdiary.com/2017/11/sharepoint-online-grant-permission-to-list-item-using-powershell.html#ixzz5Uh1cYKA2

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "Update_SharePoint_ListItem_Permissions" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.
#Load SharePoint CSOM Assemblies
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

# Local Logging
#################################
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\Update-SOLListItemPermissions_$stamp.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile $stamp
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
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
    [int]
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
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#To call non-generic method Load(list, x => x.HasUniqueRoleAssignments)
Function Invoke-LoadMethod() {
    param(
            [Microsoft.SharePoint.Client.ClientObject]$Object = $(throw "Please provide a Client Object"),
            [string]$PropertyName
        )
   $ctx = $Object.Context
   $load = [Microsoft.SharePoint.Client.ClientContext].GetMethod("Load")
   $type = $Object.GetType()
   $clientLoad = $load.MakeGenericMethod($type)
   $Parameter = [System.Linq.Expressions.Expression]::Parameter(($type), $type.Name)
   $Expression = [System.Linq.Expressions.Expression]::Lambda([System.Linq.Expressions.Expression]::Convert([System.Linq.Expressions.Expression]::PropertyOrField($Parameter,$PropertyName),[System.Object] ), $($Parameter))
   $ExpressionArray = [System.Array]::CreateInstance($Expression.GetType(), 1)
   $ExpressionArray.SetValue($Expression, 0)
   $clientLoad.Invoke($ctx,@($Object,$ExpressionArray))
}

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= 
Function Set-ListItemPermission
{
    param
    (  
        [Parameter(Mandatory=$true)] [string]$SiteURL,
        [Parameter(Mandatory=$true)] [string]$subsite,
        [Parameter(Mandatory=$true)] [string]$ListName,
        [Parameter(Mandatory=$true)] [string]$ItemID,
        [Parameter(Mandatory=$true)] [string]$PermissionLevel,
        [Parameter(Mandatory=$false)] [string]$UserID,
        [Parameter(Mandatory=$false)] [string]$Manager,
        [Parameter(Mandatory=$false)] [string]$Group,
        [Parameter(Mandatory=$false)] [string]$GroupPermissions
    )
    
    Try 
        {
            #Setup Credentials to connect
            $admin = 'flowautomation@example.com'
            $password = ConvertTo-SecureString -AsPlainText -Force -String '<password>'
            $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
 
            #Setup the context
            $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
            $Ctx.Credentials = $Credentials
         
            #Get the List and Item
            $web = $Ctx.Site.OpenWeb($subsite)
            $Ctx.Load($web)
            # $list = $Ctx.Web.Lists.GetByTitle($ListName)
            $list = $web.Lists.GetByTitle($listname)
            $ListItem=$List.GetItemByID($ItemID)
            $Ctx.Load($List)
            $Ctx.Load($ListItem)
            $Ctx.ExecuteQuery()
 
            #Check if Item has unique permission already
            Invoke-LoadMethod -Object $list -PropertyName "HasUniqueRoleAssignments"
            $Ctx.ExecuteQuery()
 
            #Break Item's permission Inheritance, if its inheriting permissions from the parent
            if (-not $ListItem.HasUniqueRoleAssignments)
            {
                $ListItem.BreakRoleInheritance($false, $false) #keep the existing permissions: No -  Clear listitems permissions: No
                $ctx.ExecuteQuery()
            }
            $output = "Successfully established a connection to SharePoint List: '$listname'. Inherited roles (if present) have been removed from list item with ID $ItemID"
            Write-host $output -ForegroundColor Cyan
            Append-Log $output
            Log_ToSplunk -Message $output -Status "Success"
        }

        Catch
            {
                $ExceptionMsg = $_.Exception.Message
                $output = "Failed - $ExceptionMsg"
                Write-Host $output -ForegroundColor Red
                Log_ToSplunk -Message $output -Status "Fail"
            }
 
    Try
        {
            #Get the User
            $User = $Ctx.Web.EnsureUser($UserID)
            $Ctx.load($User)
            $Ctx.ExecuteQuery()

            #Get the role
            $Role = $Ctx.web.RoleDefinitions.GetByName($PermissionLevel)
            $RoleDB = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($Ctx)
            $RoleDB.Add($Role)
          
            #Assign User permissions
            $UserPermissions = $ListItem.RoleAssignments.Add($User,$RoleDB)
            $ListItem.Update()
            $Ctx.ExecuteQuery()

            $output = "'$PermissionLevel' rights to List Item '$ItemID' under List Name: '$ListName' successfully granted to Employee: '$UserID'"
            Write-host $output -ForegroundColor Green
            Append-Log $output
            Log_ToSplunk -Message $output -Status "Success"
        }

        Catch
            {
                $ExceptionMsg = $_.Exception.Message
                $output = "Failed to grant '$PermissionLevel' rights to List Item '$ItemID' under List Name: '$ListName' for Employee: '$UserID' - $ExceptionMsg"
                Write-host $output -ForegroundColor Red 
                Append-Log $output
                Log_ToSplunk -Message $output -Status "Fail"
            }
    Try
        {
            #Get the SPO Group
            $Grp =$web.SiteGroups.GetByName($Group)
            $Ctx.load($Grp)
            $Ctx.ExecuteQuery()

            #Get the role
            $Role = $Ctx.web.RoleDefinitions.GetByName($GroupPermissions)
            $RoleDB = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($Ctx)
            $RoleDB.Add($Role)
          
            #Assign User permissions
            $GrpPermissions = $ListItem.RoleAssignments.Add($Grp,$RoleDB)
            $ListItem.Update()
            $Ctx.ExecuteQuery()

            $output = "'$GroupPermissions' rights to List Item '$ItemID' under List Name: '$ListName' successfully granted to SPO Group: '$Group'"
            Write-host $output -ForegroundColor Green
            Append-Log $output
            Log_ToSplunk -Message $output -Status "Success"
        }

        Catch
            {
                $ExceptionMsg = $_.Exception.Message
                $output = "Failed to grant '$GroupPermissions' rights to List Item '$ItemID' under List Name: '$ListName' for SPO Group: '$Group' - $ExceptionMsg"
                Write-host $output -ForegroundColor Red 
                Append-Log $output
                Log_ToSplunk -Message $output -Status "Fail"
            }

    Try
        {
            #Get the Mgr
            $Mgr = $Ctx.Web.EnsureUser($Manager)
            $Ctx.load($Mgr)
            $Ctx.ExecuteQuery()

            #Get the role
            $Role = $Ctx.web.RoleDefinitions.GetByName($PermissionLevel)
            $RoleDB = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($Ctx)
            $RoleDB.Add($Role)

            #Assign Mgr permissions
            $MgrPermissions = $ListItem.RoleAssignments.Add($Mgr,$RoleDB)
            $ListItem.Update()
            $Ctx.ExecuteQuery()

            $output = "'$PermissionLevel' rights to List Item '$ItemID' under List Name: '$ListName' successfully granted to Manager: '$Manager'"
            Write-host $output -ForegroundColor Green
            Append-Log $output
            Log_ToSplunk -Message $output -Status "Success"
        }

        Catch
            {
                $ExceptionMsg = $_.Exception.Message
                $output = "Failed to grant '$PermissionLevel' rights to List Item '$ItemID' under List Name: '$ListName' for Manager: '$Manager' - $ExceptionMsg"
                Write-host $output -ForegroundColor Red
                Append-Log $output
                Log_ToSplunk -Message $output -Status "Fail"
            }
}

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"
CLS
#Set parameter values
$csv = "C:\users\user2\Desktop\SPO_List_Export_FF2017_test.csv"
$SiteURL= "https://domain.sharepoint.com/sites/domainnet/"
$subsite = "IT/Office365"
$ListName = "Feedback Forward Review Form 2017 Bak"
$import = Import-Csv $csv
$Group = "Human Resources Owners"

$import | foreach{
    Write-Host ""
    Append-Log ""
    Try
        {
            $ItemID = $_.ID
            $UserID = $_.UserID
            $Manager = $_.Manager
            $PermissionLevel="Edit"
            $GroupPermissions = "Full Control"
            Set-ListItemPermission -SiteURL $SiteURL -subsite $subsite -ListName $ListName -ItemID $ItemID -UserID $UserID -Manager $Manager -Group $Group -PermissionLevel $PermissionLevel -GroupPermissions $GroupPermissions
        }

        Catch
            {
                $ExceptionMsg = $_.Exception.Message
                $output = "Failed to update permissions on List Item '$ItemID' under List Name: '$ListName' - $ExceptionMsg"
                Write-Host $output -ForegroundColor Red
                Append-Log $output
                Log_ToSplunk -Message $output -Status "Fail"
            }
    }
# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"

Exit