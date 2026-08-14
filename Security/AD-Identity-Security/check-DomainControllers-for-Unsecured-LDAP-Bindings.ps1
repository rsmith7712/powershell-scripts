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
    check-DomainControllers-for-Unsecured-LDAP-Bindings.ps1

.DESCRIPTION
    Queries the Directory Service security event log (IDs 2886/2887/2889) on domain controllers to detect unsigned or insecure LDAP bindings.

.FUNCTIONALITY
    Detects insecure LDAP bindings on domain controllers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



#Event ID 2886 in the Directory Service log indicates that LDAP signing is not enabled in your domain
Get-EventLog -LogName Security -InstanceId 2886

#If clients are relying on unsigned SASL binds or LDAP simple binds over a non-SSL/TLS connection, 
# an event (ID 2887) will be generated in the Directory Service log every 24 hours detailing the number 
# of insecure binds performed.
Get-EventLog -LogName Security -InstanceId 2887

#Event ID 2889 will be generated in the Directory Service log whenever an insecure bind is made to the DC
Get-EventLog -LogName Security -InstanceId 2889
