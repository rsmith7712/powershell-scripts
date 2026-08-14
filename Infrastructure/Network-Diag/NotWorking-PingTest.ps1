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
    NotWorking-PingTest.ps1.txt

.DESCRIPTION
    Pings servers from a list and, on failure, flushes and re-registers DNS (work in progress).

.FUNCTIONALITY
    Pings servers and refreshes DNS on failure.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#  PingTest.ps1  #>

$Servers = Get-Content -Path "C:\temp\Targets.txt"

foreach($host in $Servers)
{
  if(!(Test-Connection -Cn $host -BufferSize 16 -Count 1 -ea 0 -quiet)){
   “Problem connecting to $host”
   
   “Flushing DNS”
   ipconfig /flushdns | out-null
   
   “Registering DNS”
   ipconfig /registerdns | out-null
  
  “doing a NSLookup for $host”
   nslookup $host
   “Re-pinging $host”

     if(!(Test-Connection -Cn $host -BufferSize 16 -Count 1 -ea 0 -quiet))
      {“Problem still exists in connecting to $host”}
       ELSE {“Resolved problem connecting to $host”} #end if
   } # end if
} # end foreach