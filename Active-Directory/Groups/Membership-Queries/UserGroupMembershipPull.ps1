<#
https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Get-All-Group-167a9ce7

Retrieve all group membership of a given AD User. 
Just pass the selected/desired Username as the first parameter.

Example: UserGroupMembershipPull.ps1 <UserLoginID> ---- Press ENTER. (UserGroupMembershipPull.ps1 BobS)

Example: Multiple_UserGroup_InputFile.ps1 -CSVFile <FullPath\CSVFileName.csv>

Your InputFile.csv should be like this:
UserLoginID   <-- Don't remove/modify this header from input file
MikeB
SamanthaP


#>

[CmdletBinding(SupportsShouldProcess=$True)] 
Param( 
    [Parameter(Mandatory = $True)] 
    [String]$UserName 
) 
Import-Module ActiveDirectory 
If ($UserName) { 
    $UserName = $UserName.ToUpper().Trim() 
    $Res = (Get-ADPrincipalGroupMembership $UserName | Measure-Object).Count 
    If ($Res -GT 0) { 
        Write-Output "`n" 
        Write-Output "The User $UserName Is A Member Of The Following Groups:" 
        Write-Output "===========================================================" 
        Get-ADPrincipalGroupMembership $UserName | Select-Object -Property Name, GroupScope, GroupCategory | Sort-Object -Property Name | FT -A 
    } #Export-Csv "C:\temp\GroupMembershipPull.csv" -NoTypeInformation
}