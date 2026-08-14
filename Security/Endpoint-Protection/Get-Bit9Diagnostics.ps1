$computername = Read-Host "Enter Computername"
CLS
#    "- Copying procmon.exe to $computername -"
# ROBOCOPY "c:\localbin" "\\$computername\c$\scripts" "procmon.exe" /z /w:1 /r:1 > $null

Invoke-Command -ComputerName $computername -ScriptBlock{
  
    Set-Location "C:\Program Files\Bit9\Parity Agent"
    &cmd /c "dascli.exe password domaincorphelp"
        Start-Sleep -Seconds 02

        "- Flushing Logs - "
    &cmd /c "dascli.exe flushlogs"
        Start-Sleep -Seconds 02

        "- Setting Debug Level - "
    &cmd /c "dascli.exe debuglevel 6"
        Start-Sleep -Seconds 02

        "- Setting kerneltrace - "
    &cmd /c "dascli.exe kerneltrace 4"
        Start-Sleep -Seconds 02

        "- Setting nettrace - "
    &cmd /c "dascli.exe nettrace 1"
        Start-Sleep -Seconds 02

        "- Resetting counters - "
    &cmd /c "dascli.exe resetcounters"
        Start-Sleep -Seconds 02

        "- Configuring performance diagnostics -"
    &cmd /c "dascli.exe diagnostics +performance"
        Start-Sleep -Seconds 02

        "- Configuing Capture File - "
    if(Test-Path "C:\temp\diag.zip"){rm "C:\temp\diag.zip"}
    &cmd /c "dascli.exe capture C:\temp\diag"
        Start-Sleep -Seconds 02

        "- Configuring performance diagnostic - "
    &cmd /c "dascli.exe diagnostics -performance"
        Start-Sleep -Seconds 02

        "- Resetting parameters - "
    &cmd /c "dascli.exe debuglevel 0"
        Start-Sleep -Seconds 02
    &cmd /c "dascli.exe kerneltrace 2"
        Start-Sleep -Seconds 02
    &cmd /c "dascli.exe nettrace 0"
        Start-Sleep -Seconds 02


    Write-Host ""
    Write-Host ""
        
   <# Set-Location "C:\scripts"
        "- starting procmon capture - "
        procmon.exe /accepteula /quiet /Minimized /Backingfile C:\temp\procmon_1.pml
        "- waiting 10 minutes - "
        Start-Sleep 600
        "- terminating procmon capture - "
        procmon.exe /terminate
   #>
}

"- Copying Results Locally -"

ROBOCOPY "\\$computername\c$\scripts" "c:\temp\BIT9_Diag" "diag.zip" /z /w:1 /r:1 > $null
#ROBOCOPY "\\$computername\c$\scripts" "c:\temp\BIT9_Diag" "procmon_1.pml" /z /w:1 /r:1