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
    fixnames_2.ps1

.DESCRIPTION
    Compares an HR name export against an Active Directory export to reconcile and correct user display names (variant).

.FUNCTIONALITY
    Reconciles HR and AD user names.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$ErrorActionPreference = "SilentlyContinue"

$names = Import-Csv D:\temp\MyHR_PULL.csv | Select-Object -Property FULL_NAME,EMPLOYEE_NUMBER

$ADdata = Import-CSV D:\temp\AD_Pull.csv

#$names =@("user47","user26")

$titles = @("Mr.","Mr","Mrs.","Mrs","Ms.","Ms")

foreach($name in $names)
{
    Write-Host $name
    $firstandinitial = $name.FULL_NAME.split(",")[1]
    $firstandinitial = $firstandinitial.trim() #Drops leading space
    $firstandinitial = $firstandinitial.split(" ")
    If($titles -contains $firstandinitial[0]) # Ignores titles
    {
        $first = $firstandinitial[1]
    }
    Else
    {
        $first = $firstandinitial[0]
    }
    $last = $name.FULL_NAME.split(",")[0]
    $FirstInitial = $first.substring(0,1)
    $fullname = $first + " " + $last
    
    $Found = $Null
    Foreach($user in $ADdata)
    {
        If($fullname -match $user.FullName)
        {
            $user.EmployeeID = $name.EMPLOYEE_NUMBER
            $user.MatchType = "FullName"
            Write-Host $fullname,$user.EmployeeID
            $Found = $true
        }
    }
    IF($Found -ne $true)
    {
        Foreach($user in $ADdata)
        {
            If($Last -match $user.LastName)
            {
                If($FirstInitial -match $user.FirstName.substring(0,1))
                {
                    $user.EmployeeID = $name.EMPLOYEE_NUMBER
                    $user.MatchType = "FirstInitial/LastName"
                    Write-Host $fullname,$user.EmployeeID
                }
            }                
        }

    }
    #$fullname | Out-File C:\temp\hr_names.csv -Append
}

$ADdata | Export-CSV -path D:\Temp\ADexporttest.csv -NoTypeInformation