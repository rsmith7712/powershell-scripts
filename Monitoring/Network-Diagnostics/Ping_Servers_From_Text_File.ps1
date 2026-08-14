# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Richard Smith

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
    Ping_Servers_From_Text_File

.SYNOPSIS
    Ping a List of Servers in a Text File
    Export results to Csv

.HISTORY
    Created:  Richard Smith
    Date:     2020-08-03

.FUNCTIONALITY
    Ping a List of Servers in a Text File
        Export results to Csv

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Create a ForEach loop to test availability of each server; Export to Csv
ForEach-Object{
    $Servers = Get-Content -Path C:\Temp\servers.txt
    ForEach ($server in $Servers){
    [pscustomobject]@{
        "ServerName" = $server
        "IsOnline" = (Test-Connection -ComputerName $server -Count 1 -Quiet)
        }
    } 
} | Export-Csv C:\Temp\results.csv
