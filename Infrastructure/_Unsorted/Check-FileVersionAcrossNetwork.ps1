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
    Check-FileVersionAcrossNetwork.ps1

.DESCRIPTION
    Checks a program's file version (for example the McAfee DAT) across networked computers and logs the results.

.FUNCTIONALITY
    Reports a file version across networked computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


# I like a tidy workspace
clear

# Errors happen, just move on.  Comment this out if you want to see what broke.
$ErrorActionPreference = "silentlycontinue"

# Make a log,  
$LogTime = Get-Date -Format "MM-dd-yyyy_hh.mm.ss"
#$LogFile= 'C:\temp\<ProgramVersions>.'+$logtime+'.txt'
$LogFile= 'C:\temp\McAfee_DatVersion.'+$logtime+'.txt'
$logtime | Out-File $LogFile

# Need this to discover what computers are on the network
Import-Module ActiveDirectory
#$computer = (Get-ADComputer -Filter 'ObjectClass -eq "Computer"' | Select -Expand DNSHostName)
$servers = (Get-ADComputer -Filter {OperatingSystem -Like "Windows *Server*"} | Select -Expand DNSHostName)

$drawline=  "-----------------------------------------------------------------------------------------------------------------------"

# Get that list of computers and do something with it.

foreach ($server in $servers) {

# Define what we are looking for
$path="\\$server\c$\<ProgramFolder>*\"
$filename="<Programfile>"
$FilePath=$path+$filename

# The program we are looking for may have multiple instances.  Here's another possible location.
$path2="\\$server\c$\<ProgramFolder>*\"
$filename2="<Programfile>"
$FilePath2=$path2+$filename2

# Go find what we are looking for and log it.
if ((Get-ChildItem -Recurse $FilePath) -eq $null){
    Out-Null
    }

else {
$drawline | Tee-Object $LogFile -Append
$computer1 | Tee-Object $LogFile -Append
Get-ChildItem  -Recurse $FilePath | foreach-object { "{0,-80}`t{1}" -f $_.FullName,  [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion } |  Tee-Object $LogFile -Append
Get-ChildItem -Recurse  $FilePath2 | foreach-object { "{0,-80}`t{1}" -f $_.FullName,  [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }   | Tee-Object $LogFile -Append

$drawline| Tee-Object $LogFile -Append
}
}
<#

PowerShell Script to check file version across the network

Posted on March 23, 2017 by Frank McCourry

Our office runs an application that is constantly being updated.  Unfortunately the 
program is not easy to update via Group Policy (GPO), so instead of walking to each 
computer to check if it needs an upgrade or if it is running multiple versions, I 
wrote this script to do the legwork for me.  To modify this script simply 
change <ProgramVersions> <ProgramFolder> and <ProgramFile> to suit your needs.  You 
will also need to modify the  $LogFile variable to a path that exists on your own 
system.  It can take some time to run, especially if you have a lot of systems to 
check.  The end result is a log file that tells you where to find what you are 
looking for so you can work more efficiently.

https://www.xpertnotes.net/blog/2017/03/23/powershell-script-to-check-file-version-across-the-network/

#>