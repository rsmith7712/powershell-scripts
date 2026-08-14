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
    Set-IIS.ps1

.DESCRIPTION
    Configures an IIS default web site and application pools (ASP.NET and DriverManager) with their physical paths.

.FUNCTIONALITY
    Configures IIS sites and application pools.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$Site = "Default Web Site"
$AspAppPoolName = "ASP.NET v4.5"
$DriverAppPoolName = "DriverManager"
$SitePhysicalPath = "%SystemDrive%\inetpub\wwwroot"
$DMPhysicalPath = "C:\inetpub\wwwroot\dm"
$DriverPhysicalPath = "C:\inetpub\wwwroot\DriverManager"

$GD2PhysicalPath = "C:\inetpub\wwwroot\DriverManager\GD2WebService"

#Create a default site and set the Application Pool to ASP.NET v4.5 and Physical path: %SystemDrive%\inetpub\wwwroot
New-Item -Path "IIS:\AppPools\$AspAppPoolName"
New-WebSite -Name $Site -ApplicationPool $AspAppPoolName -Port 80 -PhysicalPath $SitePhysicalPath
#Create a Virtual directory name DM and set the path to C:\inetpub\wwwroot\dm
New-WebVirtualDirectory -Site $Site -Name "DM" -PhysicalPath $DMPhysicalPath
#Create another site name DriverManager and set the Application Pool to ‘DriverManager’ and path C:\inetpub\wwwroot\DriverManager.  Set the binding to host name - drivermanager.example.com on Port 80
New-Item -Path "IIS:\AppPools\$DriverAppPoolName"
New-WebSite -Name "DriverManager" -ApplicationPool $DriverAppPoolName -Port 80 -PhysicalPath $DriverPhysicalPath
#Create a Virtual Directory name – GD2WebService and path to C:\inetpub\wwwroot\DriverManager\GD2WebService
New-WebVirtualDirectory -Site $Site -Name "GD2WebService" -PhysicalPath $GD2PhysicalPath
#Make sure the server antivirus is configured to allow sending of email to an smtp server
#Install \\\SERVER\SHARE\...\setup.exe to the \dm folder in the default web root using the AppPool created in step 3
#Add read/write/modify permission for <SERVER>\IIS_IUSRS to the \dm\Log folder
#Add read/write/modify permission for <SERVER>\IIS_IUSRS to the \dm\Uploads folder
#Add read/write/modify permission for <SERVER>\IIS_IUSRS to the \dm\GpsFiles folder
#Share the \dm\GpsFiles folder with <DOMAIN>\Everyone for read/write