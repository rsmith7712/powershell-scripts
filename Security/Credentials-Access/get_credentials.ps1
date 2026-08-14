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
    get_credentials.ps1

.SYNOPSIS
  function for getting credentials via user input and verifying they are valid

.EXAMPLE
  If this script can be called from the command line, show examples here

.FUNCTIONALITY
    function for getting credentials via user input and verifying they are valid

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function get_credentials
{
    #Gets users admin credentials
    $cred = Get-Credential

    #below is used to verify authentication
    $username = $cred.username
    $password = $cred.GetNetworkCredential().password

    # Get current domain using logged-on user's credentials
    $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
    $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)

    #checks to make sure admin creds are valid
    if ($domain.name -eq $null)
    {
        Clear-Host
        write-host "Authentication failed - please verify your username and password." -ForegroundColor Red
        exit #terminate the script.
    }
    else
    {
        clear-host
        write-host "Credentials Succesfully Verified" -ForegroundColor Yellow
        return $cred
    }
}