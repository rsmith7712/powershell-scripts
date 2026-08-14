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
    Upload-DocumentsLocalToSharePoint.ps1

.DESCRIPTION
    Uploads documents from a local folder to a specified SharePoint Online document library.

.FUNCTIONALITY
    Uploads local documents to a SharePoint Online library.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function UploadDocuments(){
Param(
        [ValidateScript({If(Test-Path $_){$true}else{Throw "Invalid path given: $_"}})] 
        $LocalFolderLocation,
        [String] 
        $siteUrl,
        [String]
        $documentLibraryName
)
Process{
       
        $path = $LocalFolderLocation.TrimEnd('\')

        Write-Host "Provided Site :"$siteUrl -ForegroundColor Green
        Write-Host "Provided Path :"$path -ForegroundColor Green
        Write-Host "Provided Document Library name :"$documentLibraryName -ForegroundColor Green

          try{
                $credentials = Get-Credential
  
                Connect-PnPOnline -Url $siteUrl -CreateDrive -Credentials $credentials

                $file = Get-ChildItem -Path $path -Recurse
                $i = 0;
                Write-Host "Uploading documents to Site.." -ForegroundColor Cyan
                (dir $path -Recurse) | %{
                    try{
                        $i++
                        if($_.GetType().Name -eq "FileInfo"){
                          $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                          $status = "Uploading Files :'" + $_.Name + "' to Location :" + $SPFolderName
                          Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                          $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                         }          
                        }
                    catch{
                    }
                 }
            }
            catch{
             Write-Host $_.Exception.Message -ForegroundColor Red
            }

  }
}


#UploadDocuments -LocalFolderLocation {Local Folder Location} -siteUrl {Site collection URL} -documentLibraryName {Document Library Name}


