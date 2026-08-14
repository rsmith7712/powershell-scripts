IF EXIST "C:\Program Files (x86)\" GOTO x64

:x86
robocopy \\srv\scripts\...\ C:\Program" "Files\DM" "NetVu" "Observer\sites\ /mir /xd "Other"
GOTO End

:x64
robocopy \\srv\scripts\...\ C:\Program" "Files" "(x86)\DM" "NetVu" "Observer\sites\ /mir /xd "Other"
GOTO End 

:End