# LEGAL
<# LICENSE
    MIT License, Copyright 2024 Richard Smith

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
    Concord-Tech-Qs4-Code.ps1

.DESCRIPTION
    Defines role-based security and distribution group mappings (HR, IT, etc.) for onboarding in Active Directory.

.FUNCTIONALITY
    Maps roles to AD security and distribution groups.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#PowerShell
# Import the Active Directory module
Import-Module ActiveDirectory

# Define role-based group mappings
$roleGroups = @{
    "HR" = @{
        "SecurityGroups" = @("HR_SecurityGroup")
        "DistributionGroups" = @("HR_DistributionList")
    }
    "IT" = @{
        "SecurityGroups" = @("IT_SecurityGroup")
        "DistributionGroups" = @("IT_DistributionList")
    }
    "Finance" = @{
        "SecurityGroups" = @("Finance_SecurityGroup")
        "DistributionGroups" = @("Finance_DistributionList")
    }
    # Add more roles and corresponding groups as needed
}

# Function to add user to groups
function Add-UserToGroups {
    param (
        [string]$UserName,
        [string]$Role
    )
    if ($roleGroups.ContainsKey($Role)) {
        $groups = $roleGroups[$Role]
        # Add to security groups
        foreach ($group in $groups.SecurityGroups) {
            Add-ADGroupMember -Identity $group -Members $UserName -ErrorAction Stop
            Write-Host "Added $UserName to security group $group"
        }
        # Add to distribution groups
        foreach ($group in $groups.DistributionGroups) {
            Add-DistributionGroupMember -Identity $group -Member $UserName -ErrorAction Stop
            Write-Host "Added $UserName to distribution group $group"
        }
    } else {
        Write-Host "Role $Role not found."
    }
}

# Function to remove user from groups
function Remove-UserFromGroups {
    param (
        [string]$UserName,
        [string]$Role
    )
    if ($roleGroups.ContainsKey($Role)) {
        $groups = $roleGroups[$Role]
        # Remove from security groups
        foreach ($group in $groups.SecurityGroups) {
            Remove-ADGroupMember -Identity $group -Members $UserName -Confirm:$false -ErrorAction Stop
            Write-Host "Removed $UserName from security group $group"
        }
        # Remove from distribution groups
        foreach ($group in $groups.DistributionGroups) {
            Remove-DistributionGroupMember -Identity $group -Member $UserName -Confirm:$false -ErrorAction Stop
            Write-Host "Removed $UserName from distribution group $group"
        }
    } else {
        Write-Host "Role $Role not found."
    }
}

# Onboarding function
function Onboard-Employee {
    param (
        [string]$UserName,
        [string]$Role
    )
    Add-UserToGroups -UserName $UserName -Role $Role
    Write-Host "Onboarded $UserName with role $Role"
}

# Off-boarding function
function Offboard-Employee {
    param (
        [string]$UserName,
        [string]$Role
    )
    Remove-UserFromGroups -UserName $UserName -Role $Role
    Write-Host "Offboarded $UserName with role $Role"
}
# Example usage
# Onboard-Employee -UserName "jdoe" -Role "IT"
# Offboard-Employee -UserName "jdoe" -Role "IT"
