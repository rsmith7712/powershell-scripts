$computer = Read-Host "Enter Computer Name"

robocopy "\\user3\C$\...\JunosFix" "\\$computer\C$\software"

psexec \\$computer reg import C:\Software\JunosFixGUID.reg