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
    ADAdminGroups.ps1

.DESCRIPTION
    Reports the membership of the Active Directory privileged groups (Enterprise, Schema and Domain Admins) with a run date and converts the result to a PDF.

.FUNCTIONALITY
    Reports privileged AD admin-group membership to PDF.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

## This script will return the settings for the Membership of Active Directory Admin Groups (Enterprise Admins, Schema Admins and Domain Admins)
## The results will have a date inserted to verify run time and be converted to a .pdf file


## Active Directory Powershell Module is used for this cmdlet

Import-Module ActiveDirectory

Function ConvertToPDF

## This Function will convert a .txt file to a .pdf file using the MS Word COM Object
## MS Word must be installed on the system this function is run on


{
	param
	(
    ## Full file path for file to be converted must be passed to function
	$fpath
	)

$extension = [System.IO.Path]::GetExtension($fpath)
$extension = $extension.Trim()

   $File=$fpath

   $Word=NEW-OBJECT –COMOBJECT WORD.APPLICATION
   $Doc=$Word.Documents.Open($File)
   $Doc.saveas([ref] (($File).replace($extension,”.pdf”)), [ref] 17)
   $Doc.close()
}

## Main Body

$date = Get-Date

## Message is inserted into file for clarity and to validate the date script was run
$message = "DOMAIN ACTIVE DIRECTORY ADMINISTRATIVE GROUP MEMBERSHIP - RESULT OF SCRIPT RUN ON $date"

##Filepath and FileName should be set to whereever the file needs to be dropped
##Make sure to include trailing backslash in $filepath

$filepath = "E:\ScriptOut\"
$filename = "DOMAINADAdminUsers.txt"

## Produce .txt file with cmdlet output

$message | Out-File -Filepath $filepath$filename
Add-Content $filepath$filename  "`nGet-ADGroupMember Enterprise Admins -Recursive | Select SamAccountName"
Get-ADGroupMember "Enterprise Admins" -Recursive | Select-Object SamAccountName | Out-File -Filepath $filepath$filename -Append

Add-Content $filepath$filename  "`nGet-ADGroupMember Schema Admins -Recursive | Select SamAccountName"
Get-ADGroupMember "Schema Admins" -Recursive | Select-Object SamAccountName | Out-File -Filepath $filepath$filename -Append

Add-Content $filepath$filename  "`nGet-ADGroupMember Domain Admins -Recursive | Select SamAccountName"
Get-ADGroupMember "Domain Admins" -Recursive | Select-Object SamAccountName | Out-File -Filepath $filepath$filename -Append

## Convert .txt file to .pdf

ConvertToPDF $filepath$filename

## Clean up uneeded .txt file

Remove-Item $filepath$filename