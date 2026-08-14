# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    Delete-OnHourTask.ps1

.Synopsis
     Scheduled Deletion of the C:\DOCS\AUTODELETE 

.DESCRIPTION
    The stores scan sensitive information to send to corporate office.  
    We have commited to ensure that all scanned documents in this folder 
    will be deleted after the file becomes an hour old in age.
    This will also remove any folders made to ensure nothing is missed.

Author:
user21 for Domain, Inc.

.FUNCTIONALITY
    The stores scan sensitive information to send to corporate office.
        We have commited to ensure that all scanned documents in this folder
        will be deleted after the file becomes an hour old in age.
        This will also remove any folders made to ensure nothing is missed.

    Author:
    user21 for Domain, Inc.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$Now = Get-Date
    #Gets Current Day - Time
$hours = "1"
    #Defines Max Age in Hours
$TargetFolder = "C:\DOCS\AUTODELETE\"
    #Defines Folder Where Scans Will Be Located.
$LastWrite = $Now.Addhours(-$hours)
    #Creates a value to create a comparison for all items that are older that 1 hour.
$Files = get-childitem $TargetFolder -include *.*  -recurse -force
     Where {$_.CreationTime -le "$LastWrite"} 
	foreach ($i in Get-ChildItem $TargetFolder -recurse)
    #Gathers the list of items in the folder and creates a value for all items that are older than 1 hour
{
    if ($i.CreationTime -lt ($(Get-Date).AddHours(-1)))
    {
        Remove-Item $Files -recurse -force
        #write-host " deleted some items"  - this was to confirm when actions were completed
        #All items that are older than 1 hour are deleted.
    }
}
	Write-Output $Files >> c:\.delete.log
        #Log file created to validate deletion and tracking completion.
	