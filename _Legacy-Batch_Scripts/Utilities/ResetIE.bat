start RunDll32.exe InetCpl.cpl,ResetIEtoDefaults

ping 0.0.0.0 -w 1 -n 2

c:\nircmd\NirCmd.exe sendkey alt down

c:\nircmd\NirCmd.exe sendkey R press

c:\nircmd\NirCmd.exe sendkey alt up

ping 0.0.0.0 -w 1 -n 3

c:\NirCMD\nircmd win activate title "Reset Internet Explorer Settings"

c:\nircmd\NirCmd.exe sendkey enter press

ping 0.0.0.0 -w 1 -n 1

echo n | gpupdate/force