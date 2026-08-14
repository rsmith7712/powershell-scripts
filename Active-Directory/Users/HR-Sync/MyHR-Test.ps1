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
    MyHR-Test.ps1

.DESCRIPTION
    Test/WhatIf version of the HR-to-AD attribute sync: compares an HR CSV against Active Directory without committing changes.

.FUNCTIONALITY
    Previews HR-to-AD attribute changes (WhatIf).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>




$UpdatedData = Import-csv C:\Users\user4.DOMAIN\Documents\AD_MYHR.csv

$WhatIfTrack = @()

ForEach($User in $UpdatedData)
{
    # Grabs current info from AD based on the SamAccountName
    $CurrentData = Get-ADUser -Identity $User.SamAccountName -Properties Description,DisplayName,EmployeeID,GivenName,Manager,Surname,Title

    # Builds the correct DistinguishedName for the Manager using data from the spreadsheet. This would need to change if we only get Deltas.
    $Manager = $UpdatedData | Where-Object {$_.MyHRName -eq $User.MyHRManager}
    $Manager = (Get-ADUser -Identity $Manager.SamAccountName).DistinguishedName
    If(!($?))
    {
        $Manager = $Null
    }

    #This wouldn't exist in the Production Script
    $TestDump = New-Object psobject
    $TestDump | Add-Member -MemberType NoteProperty -name "ADname" -Value $CurrentData.name
    $TestDump | Add-Member -MemberType NoteProperty -name "Description" -Value ""
    $TestDump | Add-Member -MemberType NoteProperty -name "Title" -Value ""
    $TestDump | Add-Member -MemberType NoteProperty -name "DisplayName" -Value ""
    $TestDump | Add-Member -MemberType NoteProperty -name "EmployeeID" -Value ""
    $TestDump | Add-Member -MemberType NoteProperty -name "GivenName" -Value ""
    $TestDump | Add-Member -MemberType NoteProperty -name "Manager" -Value ""
    $TestDump | Add-Member -MemberType NoteProperty -name "Surname" -Value ""
    #/This wouldn't exist in the Production Script

    #Job Title
    If($CurrentData.Description -ne $User.MyHRJobTitle) 
    {
        $TestDump.Description = $User.MyHRJobTitle
    }
    If($CurrentData.Title -ne $User.MyHRJobTitle)
    {
        $TestDump.Title = $User.MyHRJobTitle
    }
    #Name
    If($CurrentData.DisplayName -ne $User.FullName)
    {
        $TestDump.DisplayName = $User.FullName
    }
    If($CurrentData.GivenName -ne $User.FirstName)
    {
        $TestDump.GivenName = $User.FirstName
    }
    If($CurrentData.Surname -ne $User.LastName)
    {
        $TestDump.Surname = $User.LastName
    }
    #MyHR EmployeeID
    If($CurrentData.EmployeeID -ne $User.EmployeeID)
    {
        $TestDump.EmployeeID = $User.EmployeeID
    }
    #Manager
    If($Manager -ne $Null)
    {
        If($CurrentData.Manager -ne $Manager)
        {
            $TestDump.Manager = $Manager
        }
    }
    $WhatIfTrack += $TestDump
}

$WhatIfTrack | Export-CSV -Path C:\Users\user4.DOMAIN\Documents\AD_MYHR_WhatIf.csv -NoTypeInformation