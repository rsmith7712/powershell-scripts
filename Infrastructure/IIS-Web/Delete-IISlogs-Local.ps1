<#

.Summary
Localy - Automatically Delete old IIS logs

.Purpose
Script to remove IIS files older than 30 days. 
Update the $LogPath to point it at your IIS log’s directory, 
change the $maxDaystoKeep value and the $outputPath value to 
tell the script where to put your logs. If files exist that 
are older than 30 days, they’ll be tossed, and a nice log 
entry created. If not, an entry will be added to the log 
stating ‘no files to delete today’ instead

.To-Do
- Copy script locally with RoboCopy to C:\Scripts folder
- Create Scheduled Task on local server
- Set task to run every Monday



.Notes
Date      2015-02-11
Author    Stephen Owen
Modified  Richard Smith

.URL
https://foxdeploy.com/2015/02/11/automatically-delete-old-iis-logs-w-powershell/


#>


$LogPath = "C:\inetpub\logs"
$maxDaystoKeep = -30
$outputPath = "C:\temp\IIS_Log_Removal.log"
 
$itemsToDelete = dir $LogPath -Recurse -File *.log | Where LastWriteTime -lt ((get-date).AddDays($maxDaystoKeep)) 
 
if ($itemsToDelete.Count -gt 0){
    ForEach ($item in $itemsToDelete){
        "$($item.BaseName) is older than $((get-date).AddDays($maxDaystoKeep)) and will be deleted" | Add-Content $outputPath
        Get-item $item | Remove-Item -Verbose
    }
}
ELSE{
    "No items to be deleted today $($(Get-Date).DateTime)"  | Add-Content $outputPath
    }
 
Write-Output "Cleanup of log files older than $((get-date).AddDays($maxDaystoKeep)) completed..."
start-sleep -Seconds 10