# LEGAL
<# LICENSE
    MIT License, Copyright 2023 URL

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
   - Get-GphEmptyGPO.ps1

.SYNOPSIS
   - Find empty GPOs, empty Computer-Settings or empty User-Settings

.FUNCTIONALITY
   - This Cmdlet can find empty Group-Policy Objects, either by name or through Pipeline.
      It has 3 Modes: Find all empty Policies, or find Policies where only Computer-Settings or User-Settings
      are enabled.
       
      .EXAMPLE
      Get-EmptyGPO -name "MyEmptyGpo"
      Tests if MyEmptyGpo has Settings. If it has not, no output is generated, elsewise the Cmdlet returns the
      Policy-Object
       
      .EXAMPLE
      Get-EmptyGPO -name "MyEmptyGpo" -Scope NoUsersettings
      Tests if MyEmptyGpo Has No User-Settings enabled, but Computer-Settings! If is completely empty, nothing
      is returned, elsewise the Policy-Object
       
      .EXAMPLE
      Get-GPO -ALL | Get-EmptyGPO
      Returns all empty Group-Policy-Objects from the Domain
       
      .EXAMPLE
      $EmptyGPOs = @(Get-GPO -ALL | Get-EmptyGPO)
      $EmptyComputerGPOs = @(Get-GPO -ALL | Get-EmptyGPO -NoComputerSettings)
      $EmptyGPOs = $EmptyGPOs + $EmptyComputerGPOs
      Returns all GPOs without Computer-Settings and alle completely empty GPOs
   
   - https://www.powershellgallery.com/packages/GroupPolicyHelper/1.0.1/Content/Get-GphEmptyGPO.ps1

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#requires -Version 2.0 -Modules GroupPolicy
function Get-GphEmptyGPO{
    # [CmdletBinding(DefaultParameterSetName='All')]
    param(
        # Name of the Group-Policy to examine
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = 'Enter the name of the Policy')]
        [Alias('displayname')]
        [string]$name,
        
        # Scope defines if only User- or Computersettings should be empty, or All of them
        [Parameter(Position = 1,
                   Parametersetname = 'ReturnPolicy')]
        [Validateset('All','NoComputerSettings','NoUsersettings')]
        [String]$Scope = 'All',

        # Returns a Report instead of the Empty Policies
        [Parameter(ParameterSetName='ReturnReport')]
        [switch]$Report
    )
    Begin{
        Import-Module -Name GroupPolicy    
    }
    Process{
        # Get an XML-Report of all Group-Policys. This may take a while, depending on the number of Policies
        [xml]$gpoReport = Get-GPOReport -ReportType Xml -name $name
        
        If ($report){
          $Computer = 'Empty'
          $User = 'Empty'
          [xml]$gpoReport = Get-GPOReport -ReportType Xml -Name $name

          If ($gpoReport.GPO.Computer.ExtensionData){
            $Computer = 'Set' 
          }
          If ($gpoReport.GPO.User.ExtensionData){
            $User = 'Set' 
          }
          $GPOSettings = New-Object -TypeName PSObject -Property @{
            Displayname    = $gpoReport.gpo.Name
            ComputerPolicy = $Computer
            UserPolicy     = $User
          }    
          $GPOSettings | 
            Where-Object { $_.Computerpolicy -eq 'Empty' -or $_.Userpolicy -eq 'Empty'} |
            Select-Object -Property DisplayName,ComputerPolicy,UserPolicy
        }
        Else{
          Switch ($Scope){
            # Test for non-exisiting user.Extensiondata-Node
            'NoUserSettings'{
              If ((-not $gpoReport.gpo.user.extensiondata) -And ($gpoReport.gpo.computer.extensiondata))
              {Get-GPO -Name $name}                
            }
            # Test for non-exisiting Computer-Extensiondata-Node
            'NoComputerSettings'{
              If (($gpoReport.gpo.user.extensiondata) -And (-not $gpoReport.gpo.computer.extensiondata))
              {Get-GPO -Name $name}   
            }
            'All'{ 
              If ((-not $gpoReport.gpo.user.extensiondata) -And (-not $gpoReport.gpo.computer.extensiondata))
              {Get-GPO -Name $name}
            }
          }
        }
    }
}