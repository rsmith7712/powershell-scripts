# FilerSync_jobQueue.ps1
# JGM, 2011-09-29
# Copies all content of the paths specified in the $srcShares array to 
# corresponding paths on the local server.
# Keeps data on all copy jobs in an array "$q".
# We will use up to 10 simultaneous robocopy operations.
 
set-psdebug -strict
 
# Initialize the log file:
[string] $logfile = "C:\Users\user5\Desktop\files_to_local.log"
remove-item $logfile -Force
[datetime] $startTime = Get-Date
[string] "Start Time: " + $startTime | Out-File $logfile -Append
 
# Initialize the Source file server root directories:
[String[]] $srcShares1 = "BlueTomato", "Software", "ISDept", "RealEstate", "HR", "BuyingDept", "DistCtrFiles", "AuditFiles", "AcctDept", "CorporateServices", `
"DMFiles", "Executive", "InternalAudit", "Inventory", "SarBox", "StoreFacilities", "XenTemplates", "DOMAINFoundation", "GeneralInfo", "PrivateLabel"
    #R25 removed from this sync process as the "text_comments" directory kills
    #robocopy.  We will sync this structure separately.
#[String[]] $srcShares2 = "\\backroom"
     
[String[]] $q = @() #queue array
 
function collectJobs { 
#Detects jobs with status of Completed or Stopped.
#Collects jobs output to log file, increments the "done jobs" count, 
#Then rebuilds the $jobs array to contain only running jobs.
#Modifies variables in the script scope.
    $djs = @(); #Completed jobs array
    $djs += $script:jobs | ? {$_.State -match "Completed|Stopped"} ;
    [string]$('$djs.count = ' + $djs.count + ' ; Possible number of jobs completed in this colletion cycle.') | Out-File $logfile -Append;
    if ($djs[0] -ne $null) { #First item in done jobs array should not be null.
        $script:dc += $djs.count; #increment job count
        [string]$('$script:dc = ' + $script:dc + ' ; Total number of completed jobs.') | Out-File $logfile -Append;
        $djs | Receive-Job | Out-File $logfile -Append; #log job output to file
        $djs | Remove-Job -Force;
        Remove-Variable djs;
        $script:jobs = @($script:jobs | ? {$_.State -eq "Running"}) ; #rebuild jobs arr
        [string]$('$script:jobs.count = ' + $script:jobs.Count + ' ; Exiting function...') | Out-File $logfile -Append
    } else {
        [string]$('$djs[0] is null.  No jobs completed in this cycle.') | Out-File $logfile -Append
    }
}
     
# Loop though the source directories:
foreach ($rootPath in $srcShares1) {
    [string] $srcPath = "\\backroom\" + $rootPath # Full Source Directory path.  
    #Switch maps the source directory to a destination volume stored in $target 
    switch ($rootPath) {
        BlueTomato {[string] $target = "\\SERVER\SHARE"}
        Software {[string] $target = "\\srv\software"}
        ISDept {[string] $target = "\\SERVER\SHARE"}
        RealEstate {[string] $target = "\\SERVER\SHARE"}
        HR {[string] $target = "\\SERVER\SHARE"}
        BuyingDept {[string] $target = "\\SERVER\SHARE"}
        DistCtrFiles {[string] $target = "\\SERVER\SHARE"}
        AuditFiles {[string] $target = "\\SERVER\SHARE"}
        AcctDept {[string] $target = "\\SERVER\SHARE"}
        CorporateServices {[string] $target = "\\SERVER\SHARE"}
        DMFiles {[string] $target = "\\SERVER\SHARE"}
        Executive {[string] $target = "\\SERVER\SHARE"}
        InternalAudit {[string] $target = "\\SERVER\SHARE"}
        Inventory {[string] $target = "\\SERVER\SHARE"}
        SarBox {[string] $target = "\\SERVER\SHARE"}
        StoreFacilities {[string] $target = "\\SERVER\SHARE"}
        XenTemplates {[string] $target = "\\SERVER\SHARE"}
        DOMAINFoundation {[string] $target = "\\SERVER\SHARE"}
        GeneralInfo {[string] $target = "\\SERVER\SHARE"}
        PrivateLabel {[string] $target = "\\SERVER\SHARE"}
    }
    #Enumerate directories to copy:
    $dirs1 = @()
    #MPG - Does only directories and no snapshots
    $dirs1 += gci $srcPath | sort-object -Property Name `
        | ? {$_.Attributes.tostring() -match "Directory"} `
        | ? {$_.Name -notmatch "~snapshot"}
    #Copy files in the root directory:
    [string] $sd = '"' + $srcPath + '"';
    [string] $dd = '"' + $target + '"';
    [Array[]] $q += ,@($sd,$dd,'"/COPY:DATSO"','"/LEV:1"' )
    # Add to queue:
    if ($dirs1[0] -ne $null) {
        foreach ($d in $dirs1) {
            [string] $sd = '"' + $d.FullName + '"';
            [string] $dd = '"' + $target + "\" + $d.Name + '"';
            $q += ,@($sd,$dd,'"/COPY:DATSO"','"/e"')
        }
    }
}
#foreach ($rootPath in $srcShares2) {   
#    [string] $srcPath = "\\backroom\" + $rootPath # Full Source Directory path.
#    #Switch maps the source directory to a destination volume stored in $target 
#    switch ($rootPath) {
#        Software\Apple {[string] $target = "\\srv\Software"}
#    }
#    #Enumerate directories to copy:
#    [array]$dirs1 = gci -Force $srcPath | sort-object -Property Name `
#        | ? {$_.Attributes.tostring() -match "Directory"}
#    if ($dirs1[0] -ne $null) {
#        foreach ($d in $dirs1) {
#            [string] $sd = '"' + $d.FullName + '"'
#            [string] $dd = '"' + $target + "\" + $d.Name + '"'
#            $q += ,@($sd,$dd,'"/COPY:DAT"','"/e"')
#        }
#    }
#}
 
[string] $queueFile = "C:\Users\user5\Desktop\files_to_local_queue.csv"
Remove-Item -Force $queueFile
foreach ($i in $q) {[string]$($i[0]+", "+$i[1]+", "+$i[2]+", "+$i[3]) >> $queueFile }
 
New-Variable -Name dc -Option AllScope -Value 0
[int] $dc = 0           #Count of completed (done) jobs.
[int] $qc = $q.Count    #Initial count of jobs in the queue
[int] $qi = 0           #Queue Index - current location in queue
[int] $jc = 0           #Job count - number of running jobs
$jobs = @()
 
while ($qc -gt $qi) { # Problem here as some "done jobs" are not getting captured.
    while ($jobs.count -lt 10) {
        [string] $('In ($jobs.count -lt 10) loop...') | out-file -Append $logFile
        [string] $('$jobs.count is now: ' + $jobs.count) | out-file -Append $logFile
        [string] $jobName = 'qJob_' + $qi + '_';
        [string] $sd = $q[$qi][0]; [string]$dd = $q[$qi][1];
        [string] $cpo = $q[$qi][2]; [string] $lev = $q[$qi][3]; 
        [string] $cmd = "& robocopy.exe $lev,$cpo,`"/dcopy:t`",`"/purge`",`"/nfl`",`"/ndl`",`"/np`",`"/r:0`",`"/mt:4`",`"/b`",$sd,$dd";
        [string] $('Starting job with source: ' + $sd +' and destination: ' + $dd) | out-file -Append $logFile
        $jobs += Start-Job -Name $jobName -ScriptBlock ([scriptblock]::Create($cmd))
        [string] $('Job started.  Incrementing $qi to: ' + [string]$($qi + 1)) | out-file -Append $logFile
        $qi++
    }
    [string] $("About to run collectJobs function...") | out-file -Append $logFile
    collectJobs
    [string] $('Function done.  $jobs.count is now: ' + $jobs.count)| out-file -Append $logFile
    [string] $('$jobs.count = '+$jobs.Count+' ; Sleeping for three seconds...') | out-file -Append $logFile
    Start-Sleep -Seconds 3
}
#Wait up to three hours for remaining jobs to complete:
[string] $('Started last job in queue. Waiting up to three hours for completion...') | out-file -Append $logFile
$jobs | Wait-Job -Timeout 10800 | Stop-Job
collectJobs
 
# Complete logging:
[datetime] $endTime = Get-Date
[string] "End Time: " + $endTime | Out-File $logfile -Append
$elapsedTime = $endTime - $startTime
[string] $out =  "Elapsed Time: " + [math]::floor($elapsedTime.TotalHours)`
    + " hours, " + $elapsedTime.minutes + " minutes, " + $elapsedTime.seconds`
    + " seconds."
$out | out-file -Append $logfile
 
#Create an error log from the session log.  Convert error codes to descriptions:
[string] $errFile = 'C:\Users\user5\Desktop\files_to_local.err'
remove-item $errFile -force
[string] $out = "Failed jobs:"; $out | out-file -Append $logfile
$jobs | out-file -Append $errFile
$jobs | % {$jobs.command} | out-file -Append $errFile
[string] $out = "Failed files/directories:"; $out | out-file -Append $errFile
Get-Content $logfile | Select-String -Pattern "backroom"`
    | select-string -NotMatch -pattern "^   Source" `
    | % {
        $a = $_.toString(); 
        if ($a -match "ERROR 32 ")  {[string]$e = 'fileInUse:        '};
        if ($a -match "ERROR 267 ") {[string]$e = 'directoryInvalid: '};
        if ($a -match "ERROR 112 ") {[string]$e = 'notEnoughSpace:   '};
        if ($a -match "ERROR 5 ")   {[string]$e = 'accessDenied:     '};
        if ($a -match "ERROR 3 ")   {[string]$e = 'cannotFindPath:   '};
        $i = $a.IndexOf("backroom");
        $f = $a.substring($i);

        Write-Output "$e$f" | Out-File $errFile -Force -Append
    }