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
    fInstall-Application.ps1

.DESCRIPTION
    Runs a software installer and evaluates the exit code (treating 0 and 3010 as success).

.FUNCTIONALITY
    Installs an application and checks the exit code.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Install-Application($install,$workdir,$installargs)
{
    Try
    {
        $return = Start-Process -Wait $install -WorkingDirectory $workdir -ArgumentList $installargs -PassThru
        $exitcode = $return.exitcode
        if (@(0,3010) -contains $return.exitcode)
        {
            $status = "[SUCCESS] : Software installation succeeded. Exit code: $exitcode."
            $color = "Green"
        }
            else
            {
                $status = "[ERROR] : Software installation failed. Exit code: $exitcode"
                $color = "Red"
            }
    }
        Catch
        {
            $status = "[ERROR] : Software installation failed. $($_.Exception.Message)."
            $color = "Red"
        }
    Append-Log -message $status
    Return-Output -message $status -color $color
}#===================[End Function]===================

        10
            {
                $output = "[Software Step:$($step)] Install ApplicationTools.msi."
                Append-Log -message $output
                Return-Output $output -color white
                $install = "c:\software\globalstore\globalstore"
                Install-MSI -install $install
                Set-Step -rebootflag 0
            }#-------------------[End Step]-------------------     


Install-Application -install "Datalogic OPOS 1_13_0044.msi" -workdir "c:\Software\Windows10 OPOS Drivers\Scanner" -installargs "/passive"
Install-Application -install "msiexec.exe" -workdir "c:\software\globalstore\globalstore" -installargs @("/i","ApplicationTools.msi","/qn")