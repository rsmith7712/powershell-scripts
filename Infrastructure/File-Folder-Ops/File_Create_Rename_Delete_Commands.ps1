# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    File_Create_Rename_Delete_Commands.ps1

.DESCRIPTION
    Reference snippets for creating, renaming and deleting files in PowerShell.

.FUNCTIONALITY
    File create/rename/delete command reference.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>





#Create a File If Not Exists

if (!(Test-Path "C:\temp\psversion_*.txt"))
{
    New-Item -path C:\temp -name sample.txt -type "file" -value "my new text"
}
else
{
    Add-Content -path C:\temp\sample.txt -value "new text content"
}





#Rename-item and override even if exist
Get-ChildItem psversion_.*.txt |ForEach-Object {
    $NewName = $_.Name -replace "^(psversion_\.)(.*)",'$2'
    $Destination = Join-Path -Path $_.Directory.FullName -ChildPath $NewName
    Move-Item -Path $_.FullName -Destination $Destination -Force
}




#Delete a File If One Exists
$Results = "C:\temp\psversion_*.csv"
If(Test-Path $Results)
    {
    Remove-Item $Results -Force
	}
Else{}