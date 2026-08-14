# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Force-PasswordChange.ps1

.SYNOPSIS
  Name: Force-PasswordChange.ps1
  The purpose of this script is to force users under specific Organizational Unit
  to change their password
  
.DESCRIPTION
  This is a script that you provide the Organizational Unit in Active Directory, that
  you need to force your users to change their password. It removes the option for the
  password not to expire, enabled the option of the user to force him / her to change
  the password the next time it will login.

.RELATED LINKS
  https://www.sconstantinou.com

.PARAMETER OrganizationalUnit
  In this parameter you need to specify the DistinguishedName of an Organizational Unit in
  order to force password change for the users under that Organizational Unit only.

.PARAMETER User
  For this parameters you need to specify the SamAccountName of a user in your Active Directory
  to force password change only to that user.

.NOTES
  Version:      1.0
    
  Release Date: 06-03-2018
   
  Author: Stephanos Constantinou

.EXAMPLE
  Run the script against the entire domain.
  Force-PasswordChange.ps1

  Run the script for specific Organizational Unit
  Force-PasswordChange.ps1 -OrganizationalUnit "OU=Accounting Users,DC=domain,DC=COM"

  Run the script for specific user
  Force-PasswordChange -User "stephanos"

.FUNCTIONALITY
    This is a script that you provide the Organizational Unit in Active Directory, that
      you need to force your users to change their password. It removes the option for the
      password not to expire, enabled the option of the user to force him / her to change
      the password the next time it will login.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Param(
[string]$OrganizationalUnit = "",
[string]$User = ""
)

$ErrorActionPreference = 'Stop'

Import-Module ActiveDirectory

cd ad:


Switch -Regex ($OrganizationalUnit , $Users){
    {($OrganizationalUnit -ne "") -and ($User -eq "")}{
        $InputStatus = "Wrong"
        
        while ($InputStatus -eq "Wrong") {
            $UserInput = ""
            $AllUsersInfo = Write-Host "Are you sure that you want to force change password for ALL users under this Organizational Unit? [Yes/No] (Deafult: No): " -ForegroundColor Red -NoNewline
            $UserInput = Read-Host
            

            Switch -Regex ($UserInput){
                {($UserInput -ieq "yes") -or ($UserInput -ieq "y")}{

                    Write-Host "Trying to get Organizational Unit details from Active Directory..."
                    try{$OU = Get-ADOrganizationalUnit -Identity $OrganizationalUnit -ErrorAction Stop}
                    catch{
                        Write-Warning "The script was not able to find the Organizational Unit"
                        break}
                    Write-Host "Organizational Unit details have been retrieved!!!" -ForegroundColor Green        
                    Write-Host "Retrieving users from Active Directory under" $OU.DistinguishedName
                    try{$Users = Get-ADUser -Filter * -Properties * -SearchBase "$OU" -ErrorAction Stop}
                    catch{
                        Write-Warning "The script was not able to retrieve the users under the Organizational Unit"
                        break}

                    If ($Users -ne $null){
                        Write-Host "Users Retrieved!!!" -ForegroundColor Green

                        foreach ($User in $Users){
                            try{Set-ADUser -Identity $User -ChangePasswordAtLogon $true -CannotChangePassword $false -PasswordNeverExpires $false -ErrorAction Stop}
                            catch{
                                Write-Warning "The script was not able to force password change for" $User.SamAccountName
                                break}
                            Write-Host "Password Change has been forced for" $User.SamAccountName -ForegroundColor Green
                        }
                        $InputStatus = "Correct"
                        Break
                    }
                    else{
                        Write-Host "There are no users under" $OU.DistinguishedName
                        Write-Host "Exiting..."
                        $InputStatus = "Correct"
                        Break
                    }
                    
                    Break
                }
                {($UserInput -ieq "no") -or ($UserInput -ieq "n") -or ($UserInput -eq "")}{
                
                    Write-Host "Exiting..."
                    $InputStatus = "Correct"
                    Break
                }
                default {
                
                    Write-Host "Your input is wrong. Please try again"
                    $InputStatus = "Wrong";Break}
            }
        };Break
    }
    {($OrganizationalUnit -eq "") -and ($User -ne "")}{
    
        Write-Host "Trying to get user details from Active Directory..."
        try{$ADUser = Get-ADUser -Identity $User -ErrorAction Stop}
        catch{
            Write-Warning "The script was not able to retrieve user details for" $User
            break}
        Write-Host "Details for" $ADUser.SamAccountName "has been retrieved from Active Directory" -ForegroundColor Green
        try{Set-ADUser -Identity $ADUser -ChangePasswordAtLogon $true -CannotChangePassword $false -PasswordNeverExpires $false -ErrorAction Stop}
        catch{
            Write-Warning "The script was not able to force password change for" $User.SamAccountName
            break}
        Write-Host "Password Change has been forced for" $ADUser.SamAccountName -ForegroundColor Green;Break
    }
    {($OrganizationalUnit -eq "") -and ($User -eq "")}{
        
        $InputStatus = "Wrong"

        While ($InputStatus -eq "Wrong") {
            
            $Caution = @"

CAUTION CAUTION CAUTION

It is dangerous to force password change on ALL user objects under the domain.

"@

            Write-Host $Caution -ForegroundColor Red
            $AllUsersInfo = Write-Host "Are you sure that you want to force change password for ALL user objects in Active Directory? [Yes/No] (Deafult: No): " -ForegroundColor Red -NoNewline
            $UserInput = Read-Host

            Switch -Regex ($UserInput){
                {($UserInput -ieq "yes") -or ($UserInput -ieq "y")}{
        
                    Write-Host "Retrieving Domain..."
                    try{$Domain = (Get-ADDomain -ErrorAction Stop).DistinguishedName}
                    catch{
                        Write-Warning "The script was not able to retrieve the domain"
                        break}
                    Write-Host "Domain has been retrieved!!!" -ForegroundColor Green
                    Write-Host "Retrieving all users from Active Directory..."
                    try{$Users = Get-ADUser -Filter * -Properties * -SearchBase "$Domain" -ErrorAction Stop}
                    catch{
                        Write-Warning "The script was not able to retrieve the users inthe domain."
                        break}

                    foreach ($User in $Users){
                        try{Set-ADUser -Identity $User -ChangePasswordAtLogon $true -CannotChangePassword $false -PasswordNeverExpires $false -ErrorAction Stop}
                        catch{
                            Write-Warning "The script was not able to force password change for" $User.SamAccountName
                            break}
                        Write-Host "Password Change has been forced for" $User.SamAccountName -ForegroundColor Green}
                    $InputStatus = "Correct"
                    Break
                }
                {($UserInput -ieq "no") -or ($UserInput -ieq "n") -or ($UserInput -eq "")}{
                
                    $InputStatus = "Correct"
                    Write-Host "Exiting..."
                    Break
                }
                default {
                
                    Write-Host "Your input is wrong. Please try again." -ForegroundColor Red
                    $InputStatus = "Wrong";Break
                }
            }
        };Break
    }
    default {"Something went wrong. Please run the script again and check the values you have entered";Break}
}