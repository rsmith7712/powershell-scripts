#--------------------------------------------------------------------------------- #The sample scripts are not supported under any Microsoft standard support #program or service. The sample scripts are provided AS IS without warranty  #of any kind. Microsoft further disclaims all implied warranties including,  #without limitation, any implied warranties of merchantability or of fitness for #a particular purpose. The entire risk arising out of the use or performance of  #the sample scripts and documentation remains with you. In no event shall #Microsoft, its authors, or anyone else involved in the creation, production, or #delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, #loss of business information, or other pecuniary loss) arising out of the use #of or inability to use the sample scripts or documentation, even if Microsoft #has been advised of the possibility of such damages #--------------------------------------------------------------------------------- 

[CmdletBinding(SupportsShouldProcess=$true)]

Param
(
    [String[]]$ComputerName = $env:COMPUTERNAME
)

Foreach($Computer in $ComputerName)
{
    #Printer has several possible states,we filter value 2 and value 6.
    $PrinterInfo = Get-WmiObject -Class Win32_Printer -ComputerName $ComputerName `
     -Namespace "root\CIMV2" | Where{$_.PrinterState -eq "2" -or $_.PrinterState -eq "6"}

    If ($PSCmdlet.ShouldProcess("Cancel print job(s)","Printer"))
    {
        If($PrinterInfo)
        {
            Try
            {
                Write-Verbose "Cancelling printer jobs."
                $PrinterInfo | Foreach{$_.CancelAllJobs()}
                Write-Host "Successfully cancel print job(s)."
            }
            Catch
            {
                Write-Host "Failed to cancel print jobs stuck in the print queue."
            }
        }
        Else
        {
            Write-Host "Cannot find any print jobs stuck in the print queue."
        }
    }
}