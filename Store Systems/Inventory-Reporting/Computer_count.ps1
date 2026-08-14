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
    Computer_count.ps1

.DESCRIPTION
    Counts store computers (store, jumpstart, additional and tag) per store from Active Directory into a master list.

.FUNCTIONALITY
    Counts store computers by type.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$storecomputers = @()
$storecomputers = Get-ADComputer -Filter * -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com"
$storecomputers += Get-ADComputer -Filter * -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com"
$storecomputers += Get-ADComputer -Filter * -SearchBase "ou=store additional computers,ou=store computers,dc=domain,dc=com"

$tagcomputers = @()
$tagcomputers = Get-ADComputer -Filter * -SearchBase "ou=store ticket computer,ou=store computers,dc=domain,dc=com"

$masterlist = @()
$masterlist += "Store, Store Computers, Tag Computers"

$store = 1003
do
{
    $comparestring = "$store" + "*"
    $computercount = ($storecomputers | Where-Object {$_.name -like $comparestring}).count
    $tagcount = ($tagcomputers | Where-Object {$_.name -like $comparestring}).count

    if($computercount -ne "0")
    {
        $masterlist += "$store, $computercount, $tagcount"
    }
    $store++
}
until($store -eq "1214")

$store = 2001
do
{
    $comparestring = "$store" + "*"
    $computercount = ($storecomputers | Where-Object {$_.name -like $comparestring}).count
    $tagcount = ($tagcomputers | Where-Object {$_.name -like $comparestring}).count

    if($computercount -ne "0")
    {
        $masterlist += "$store, $computercount, $tagcount"
    }
    $store++
}
until($store -eq "2160")

$store = 3000
do
{
    $comparestring = "$store" + "*"
    $computercount = ($storecomputers | Where-Object {$_.name -like $comparestring}).count
    $tagcount = ($tagcomputers | Where-Object {$_.name -like $comparestring}).count

    if($computercount -ne "0")
    {
        $masterlist += "$store, $computercount, $tagcount"
    }
    $store++
}
until($store -eq "3020")

$store = 5000
do
{
    $comparestring = "$store" + "*"
    $computercount = ($storecomputers | Where-Object {$_.name -like $comparestring}).count
    $tagcount = ($tagcomputers | Where-Object {$_.name -like $comparestring}).count

    if($computercount -ne "0")
    {
        $masterlist += "$store, $computercount, $tagcount"
    }
    $store++
}
until($store -eq "5030")

$store = 8000
do
{
    $comparestring = "$store" + "*"
    $computercount = ($storecomputers | Where-Object {$_.name -like $comparestring}).count
    $tagcount = ($tagcomputers | Where-Object {$_.name -like $comparestring}).count

    if($computercount -ne "0")
    {
        $masterlist += "$store, $computercount, $tagcount"
    }
    $store++
}
until($store -eq "8015")

$masterlist | Out-File C:\temp\computer_count.csv -Force -Encoding utf8