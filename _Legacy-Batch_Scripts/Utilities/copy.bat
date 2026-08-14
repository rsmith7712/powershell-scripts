net use V: \\SERVER\SHARE\...\Microsoft
net use W: \\SERVER\SHARE\...\Outlook
copy V:\*.nk2* W:\ /y
net use /delete V: /y
net use /delete W: /y

start C:\"Program Files"\"Microsoft Office"\Office14\OUTLOOK.EXE /importnk2