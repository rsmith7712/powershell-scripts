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
    Get-ShareInfo.ps1

.DESCRIPTION
    Presents a folder-selection dialog rooted at a file share to choose a folder for further processing.

.FUNCTIONALITY
    Prompts to select a folder on a share.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


Function Get-Folder()
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.OpenFileDialog
    $foldername.InitialDirectory = "\\SERVER\SHARE\sys"
    $foldername.ValidateNames = $false
    $foldername.CheckFileExists = $false
    $foldername.CheckPathExists = $true
    $foldername.FileName = "Folder Selection"

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder = [System.IO.Path]::GetDirectoryName($foldername.filename)
    }
    Else{
        Exit
    }
    return $folder
}

function Save-File() 
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $initialDirectory = $ENV:USERPROFILE+"\Desktop"
    $OpenFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() |  Out-Null
 
    return $OpenFileDialog.filename
} 

$infoArray = @()
$targetFolder = Get-Folder
$ACL = (Get-ACL $targetFolder).access
$savePath = Save-File
$infoArray += "User, Permissions"
ForEach($User in $ACL){
    $infoArray += "$($User.IdentityReference),""$($User.FileSystemRights)"""
    #Add-Content -Path .\users.csv -value "$($User.IdentityReference),""$($User.FileSystemRights)"""
}

try {
    $Stream = [System.IO.StreamWriter] $savePath
    $infoArray | ForEach-Object {
        $Stream.WriteLine($_)
    }
}
finally {
    $Stream.Close()
}

Invoke-Item $savePath