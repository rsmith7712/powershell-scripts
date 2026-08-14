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
    Set-External_NTP_TimeSource.ps1

.DESCRIPTION
    Configures the Windows Time service to use an external NTP time source (with registry notes and commented commands).

.FUNCTIONALITY
    Configures an external NTP time source.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<# 

.REGISTRY_ENTRY
    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Servcices\W32Time\Parameters\Type
    Type needs to be set to NTP


#>

#external time source - switch to this once NetOps opens NTP port to TIme.Nist.Gov
#w32tm /config /manualpeerlist:"time.nist.gov,0x1" /syncfromflags:MANUAL /reliable:YES /update

#use until external NTP access is opened
#w32tm /config /manualpeerlist:"srv.example.com srv.example.com" /syncfromflags:MANUAL /reliable:YES /update

#Stop-Service w32time

#Start-Service w32time

#check sync status
w32tm /query /status

w32tm /query /peers 