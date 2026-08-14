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
    MyHR-toAD.ps1

.DESCRIPTION
    Updates Active Directory user attributes (title, manager, employee ID, etc.) from an HR CSV, tracking the changes made.

.FUNCTIONALITY
    Syncs HR data into AD user attributes.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>




$UpdatedData = Import-csv .\Path-to.csv

$TrackChanges = 

ForEach($User in $UpdatedData)
{
    # Grabs current info from AD based on the SamAccountName
    $CurrentData = Get-ADUser -Identity $User.SamAccountName -Properties Description,DisplayName,EmployeeID,GivenName,Manager,Surname,Title

    # Builds the correct DistinguishedName for the Manager using data from the spreadsheet. This would need to change if we only get Deltas.
    $Manager = $UpdatedData | Where-Object {$_.MyHRName -eq $User.MyHRManager}
    $Manager = (Get-ADUser -Identity $Manager.SamAccountName).DistinguishedName
    If(!($?)) #Sets the Manager to $Null if the previous command failed.
    {
        $Manager = $Null
    }

    #Job Title
    If($CurrentData.Description -ne $User.MyHRJobTitle) 
    {
        $CurrentData.Description = $User.MyHRJobTitle
    }
    If($CurrentData.Title -ne $User.MyHRJobTitle)
    {
        $CurrentData.Title = $User.MyHRJobTitle
    }
    #Name
    If($CurrentData.DisplayName -ne $User.FullName)
    {
        $CurrentData.DisplayName = $User.FullName
    }
    If($CurrentData.GivenName -ne $User.FirstName)
    {
        $CurrentData.GivenName = $User.FirstName
    }
    If($CurrentData.Surname -ne $User.LastName)
    {
        $CurrentData.Surname = $User.LastName
    }
    #MyHR EmployeeID
    If($CurrentData.EmployeeID -ne $User.EmployeeID)
    {
        $CurrentData.EmployeeID = $User.EmployeeID
    }
    #Manager
    If($CurrentData.Manager -ne $Manager)
    {
        $CurrentData.Manager = $Manager
    }
    
    Set-ADUser -instance $CurrentData
}