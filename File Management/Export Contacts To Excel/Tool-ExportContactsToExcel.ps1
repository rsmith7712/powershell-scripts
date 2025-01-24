# LEGAL
<# LICENSE
    MIT License, Copyright 2007 Kent Finkle

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
   Tool-ExportContactsToExcel.ps1

.SYNOPSIS
    Use Powershell to Export Contact Information to Microsoft Excel

.FUNCTIONALITY

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts - Tool-Export Contacts To Excel
#>

#-----------------------------------------------------
function Release-Ref ($info) {
foreach ( $p in $args ) { 
([System.Runtime.InteropServices.Marshal]::ReleaseComObject(
[System.__ComObject]$p) -gt 0)
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers() 
} 
}
#-----------------------------------------------------
$olFolderContacts = 10
 
$objOutlook = new-object -comobject outlook.application
 
$n = $objOutlook.GetNamespace("MAPI")
 
$colContacts = $n.GetDefaultFolder($olFolderContacts).Items
 
$xl = new-object -comobject excel.application
$xl.Visible = $True
$wb = $xl.Workbooks.Add()
 
$ws = $wb.Worksheets.Item(1)
$ws.Cells.Item(1, 1).Value() = "First Name"
$ws.Cells.Item(1, 2).Value() = "Last Name"
$ws.Cells.Item(1, 3).Value() = "Department"
$ws.Cells.Item(1, 4).Value() = "E-mail Address"

$i = 2
 
foreach ($c In $colContacts) { 

    if ( $c.Email1DisplayName -ne $Null ) {

        $email = $c.Email1DisplayName.Split( '(' )

        $ws.Cells.Item($i, 1).Value() = $c.FirstName
        $ws.Cells.Item($i, 2).Value() = $c.LastName
        $ws.Cells.Item($i, 3).Value() = $c.Department

        $email = $email[1].TrimEnd( ')' )
        $ws.Cells.Item($i, 4).Value() = $email
	$i++
    }
}
$r = $objWorksheet.UsedRange
$r.EntireColumn.Autofit
$a = Release-Ref $r $ws $wb $xl