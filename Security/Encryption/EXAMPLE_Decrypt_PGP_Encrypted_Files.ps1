# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    EXAMPLE_Decrypt_PGP_Encrypted_Files.ps1

.SYNOPSIS
  Decrypt-Files.ps1
 
.DESCRIPTION
 Decrypt-Files.ps1 decrypts pgp encrypted file(s) where the corresponding private pgp certificate is already installed (exists on the 'keyring' of the user) on the computer from which 
 this script is being executed.

 * Must have the correct PGP certificate(s) installed on the computer from which this script is executed.
 * Requires gpg.exe

    https://www.gpg4win.org/

.EXAMPLE
  
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:   8/3/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 ( 8/3/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Decrypt-Files.ps1 decrypts pgp encrypted file(s) where the corresponding private pgp certificate is already installed (exists on the 'keyring' of the user) on the computer from which
     this script is being executed.

     * Must have the correct PGP certificate(s) installed on the computer from which this script is executed.
     * Requires gpg.exe

        https://www.gpg4win.org/

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Decrypt-Files{
Param (
    [parameter(Mandatory=$true)]
    [String]
    $tempfolder,

    [parameter(Mandatory=$true)]
    [String]
    $decryptfolder,

    [parameter(Mandatory=$true)]
    [String]
    $pw
    )

    $filecount = (Get-ChildItem $tempfolder | Measure-Object).Count

    If( $filecount -eq 0){
        $ouput = "ERROR: File decryption failed.  On $env:COMPUTERNAME, no files were found in '$tempfolder' to decrypt."
        Write-Host $ouput -ForegroundColor Red
        Exit 1
        }

        Else{
        $files = @("USER.CSV", "COSTCENTER.CSV", "POSITION.CSV")

        $files | foreach{
            [string]$file = $_
            Write-Host "Decrypting $file..." -ForegroundColor Yellow
                Try
                {
                    # Decrypt file(s) using gpg.exe. 
                    # '--pinentry-mode=loopback' is required to prevent gpg.exe from prompting for a password

                    cmd /c "C:\Program Files (x86)\gnupg\bin\gpg.exe" --yes --always-trust --pinentry-mode=loopback --ignore-mdc-error --passphrase $pw --output $decryptfolder\$file --decrypt $tempfolder\$file

                    $output = "File '$file' successfully decrypted. Exit code:$LastExitCode."
                    Write-Host $output -ForegroundColor Green
                }
                Catch
                {
                    $output = "ERROR: File decryption failed. Exit code:$LastExitCode. $($_.Exception.Message)"
                    Write-Host $output -ForegroundColor Red
                }
        }
    }
}

Decrypt-Files -tempfolder "C:\temp\temp" -decryptfolder "C:\temp\decrypted" -pw "<password>"