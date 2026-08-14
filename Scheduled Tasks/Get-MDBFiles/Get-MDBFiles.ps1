
$outfile = "C:\temp\mdbfiles.txt"

    # "$env:COMPUTERNAME" | Out-File $outfile -Append ascii
    cmd /c dir /b c:\ /s | findstr /E /I /C:".mdb" | Out-File $outfile #-Append ascii