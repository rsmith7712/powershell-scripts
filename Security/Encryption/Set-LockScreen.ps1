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
    Set-LockScreen.ps1

.DESCRIPTION
    Displays a full-screen WPF 'busy' overlay window while a payload script block runs.

.FUNCTIONALITY
    Shows a busy/lock-screen overlay window.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function Set-LockScreen([ScriptBlock] $Payload={Start-Sleep -Seconds 5}, $Title='Busy, go away.')
{
    try
    {
      $window = New-Object Windows.Window
      $label = New-Object Windows.Controls.Label
      #$label.
      $label.Content = $Title
      $label.FontSize = 60
      $label.FontFamily = 'Consolas'
      $label.Background = 'Transparent'
      $label.Foreground = 'Blue'
      $label.HorizontalAlignment = 'Center'
      $label.VerticalAlignment = 'Center'

      $Window.AllowsTransparency = $True
      $Window.Opacity = .7
      $window.WindowStyle = 'None'
      $window.Content = $label
      $window.Left = $window.Top = 0
      $window.WindowState = 'Maximized'
      $window.Topmost = $true

      $null = $window.Show()
      Invoke-Command -ScriptBlock $Payload
    }
    finally { $window.Close() }
}#==============[ END FUNCTION ]==============

$job = 
{ 
  Get-ChildItem c:\windows -Recurse -ErrorAction SilentlyContinue
}

Set-LockScreen -Payload $job -Title "DOMAIN Ticketing Computer Configuration in Progress.`n`nPlease Wait..."
