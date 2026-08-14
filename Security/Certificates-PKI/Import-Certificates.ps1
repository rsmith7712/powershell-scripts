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
    Import-Certificates.ps1

.DESCRIPTION
    Imports certificates into the Trusted Publishers certificate store via certutil, reporting success or failure.

.FUNCTIONALITY
    Imports certificates into the Trusted Publishers store.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Import-Certificates($certificates)
{
    foreach($certificate in $certificates){
        Try
        {
            certutil -addstore "TrustedPublisher" "$certificate"
            If ($LASTEXITCODE -ne 0){
                    $output = "ERROR: Failed to import Seagull Scientific certificate into the Trusted Publishers certificate store ($certificate). Lastexitcode=$LASTEXITCODE"
                }
                else{
                    $output = "SUCCESS: Successfully imported Seagull Scientific certificate into the Trusted Publishers certificate store ($certificate). Lastexitcode=$LASTEXITCODE"
                }
        }
        Catch
            {
                $output = "ERROR: Failed to import Seagull Scientific certificates for Toshiba printers. Exception: $($_.Exception.Message). Lastexitcode=$LASTEXITCODE"
            }
        Finally
            {
                #Append-Log $output
                Write-Host $output -ForegroundColor Yellow
            }
    }
}
#Install Trusted Certificates
$certificates = @("C:\Software\TP8K\Drivers\Seagull\2019.1\SeagullPublisher.cer","C:\Software\TSC\TDP-324\seagull.cer")
Import-Certificates -certificates $certificates
