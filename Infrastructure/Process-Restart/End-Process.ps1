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
    End-Process.ps1

.DESCRIPTION
    Terminates a named process, attempting a graceful close before forcing it.

.FUNCTIONALITY
    Kills a named process.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function End-Process($processtokill)
{
    cls
    $ErrorActionPreference = "Stop"
    Try
    {
        $killme = Get-Process $processtokill
        $killme |
        ForEach-Object {
                    $killmesoftly = $_.CloseMainWindow()
                    if (!($killmesoftly -eq $true))
                    {
                        $murderme = $($_.Kill())
                        if ($?)
                        {
                            $output = "$processtokill processes ($($killme.ID)) all got murdered with force. It was quite a mess :("
                        }
                            else
                            {
                                $output = "Unable to murder $processtokill. Tried twice. Looks like $processtokill is immortal. :(" 
                            }
                    }
                        else
                        {
                            $output = "$processtokill got killed softly.  Not too much suffering. Yay! ;)"
                        }
                }
    }
        Catch
        {
            $output = "OOPS! :( Looks like we got an Exception.`n`nHere's what this box is saying...`n`n $($_.Exception.Message)"
        }
    Finally
    {
        Write-Host "Ok So here's what happened...`n" -ForegroundColor Yellow
        $ErrorActionPreference = "Continue"
    }
    return $output
}
Clear-Host
$processtokill = Read-Host "Enter Process name to Kill, and we'll see what we can do ("
$End_It = End-Process -processtokill $processtokill
Write-Host $End_It -ForegroundColor Magenta