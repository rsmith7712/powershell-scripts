# LEGAL
<# LICENSE
    MIT License, Copyright 2015 Richard Smith

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
    Install-Java.ps1

.SYNOPSIS
  Java Installer, Post vCommander.
 
.DESCRIPTION
  Silently installs Java, parts pulled from below URL.
  https://skarlso.github.io/2015/06/30/powershell-can-also-be-nice-or-installing-java-silently-and-waiting/
  
.NOTES
  Version:        1.0
  Author:         user26
  Creation Date:  03/09/2017
  Purpose/Change: Initial Script Development

.HISTORY

.FUNCTIONALITY
    Silently installs Java, parts pulled from below URL.
      https://skarlso.github.io/2015/06/30/powershell-can-also-be-nice-or-installing-java-silently-and-waiting/

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$ErrorActionPreference = "SilentlyContinue"
$VerbosePreference = "Continue" #Change this to "SilentlyContinue" before production use.
$JavaExePath = "\\SERVER\SHARE\...\jdk-8u102-windows-x64.exe"
$JavaPath = "C:\Program Files\Java"

If(Test-Path $JavaPath) #Checks if Java is already installed.
{
    Write-Verbose -Message "Java is already installed, exiting."
    Start-Sleep 5 
    Exit 0
}

try {
Write-Verbose -Message "Installing Java."
$InstallJava = Start-Process -FilePath $JavaExePath -ArgumentList "/s" -Wait -PassThru
$InstallJava.WaitForExit()
} catch [Exception] {
    Write-Verbose '$_ is' $_
    Write-Verbose '$_.GetType().FullName is' $_.GetType().FullName
    Write-Verbose '$_.Exception is' $_.Exception
    Write-Verbose '$_.Exception.GetType().FullName is' $_.Exception.GetType().FullName
    Write-Verbose '$_.Exception.Message is' $_.Exception.Message
}

If(Test-Path $JavaPath) #Checks the install path, exits with code depending on what happened.
{
    Write-Verbose -Message "Java installed successfully."
    Start-Sleep 5
    Exit 0
}
else 
{
    Write-Verbose -Message "Java did not install successfully."
    Start-Sleep 5
    Exit 1    
}