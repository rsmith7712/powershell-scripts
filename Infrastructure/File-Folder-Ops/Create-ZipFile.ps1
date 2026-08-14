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
    Create-ZipFile.ps1

.DESCRIPTION
    Provides functions to compress a file into a zip archive and to expand an archive.

.FUNCTIONALITY
    Zips and unzips files.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$fileToZip = 'c:\Temp\Temp\Test\test.txt'
$destinationZip = "c:\Temp\Temp\logs.zip"

Function zipFile ($fileToZip, $destinationZip) {
    compress-archive -path $fileToZip -destinationpath $destinationZip -compressionlevel optimal
}

Function unzipFile ($destinationZip) {
    expand-archive -path $destinationZip -destinationpath '.\'
}

########################################
# Script Starts 
########################################

zipFile $fileToZip $destinationZip # zip file 

unzipFile $destinationZip # Unzip file to current directory 

########################################
# Script Ends
########################################