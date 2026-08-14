$comments = @'
Script name: Export-ContactsToExcel.ps1
Created on: Friday, July 27, 2007
Author: Kent Finkle
Purpose: How can I use Windows Powershell to
Export Contact Information to Microsoft Excel?
'@
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
