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
    Install-DotNet452.ps1

.DESCRIPTION
    Silently installs the .NET Framework 4.5.2 redistributable.

.FUNCTIONALITY
    Installs .NET Framework 4.5.2.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Install .NET framework 4.52
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Install-DotNet452
{
    param(
    [string]$installpath = ".\NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
    )
    Try
    {
        $msiArgumentList =  @("/c", "$installpath", "/q" ,"/norestart")
        $return = Start-Process  cmd.exe -ArgumentList $msiArgumentList -Wait -PassThru
        $exitcode = $return.exitcode
        If (@(0,3010) -contains $return.exitcode)
        {
            $output = "SUCCESS: .NET 4.52 installation completed successfully. Exit code: $exitcode."
        }
            Else
            {
                $output = "ERROR: .NET 4.52 installation failed . Exit code: $exitcode"
            }
    }
        Catch
        {
            $output = "ERROR: .NET 4.52 installation failed. $($_.Exception.Message)"
        }
    return $output
}
Install-DotNet452 -installpath "C:\CORNERSTONE\cornerstone_np\ISSetupPrerequisites\{C4366B56-BE8F-41DA-AEFC-CB5165ADB5D3}\NDP452-KB2901907-x86-x64-AllOS-ENU.exe"