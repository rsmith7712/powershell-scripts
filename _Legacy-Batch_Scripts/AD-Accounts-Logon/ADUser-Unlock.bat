@echo off
powershell.exe -Command "& {Import-Module ActiveDirectory; Read-Host "Enter the User Account to Unlock" | Unlock-ADAccount}"