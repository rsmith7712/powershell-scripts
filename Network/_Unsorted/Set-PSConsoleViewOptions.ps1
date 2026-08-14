# Functions to hide/show console window.  Found here: https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5/view/Discussions
###############################################################
Add-Type -Name WinAPI -Namespace Native -MemberDefinition '
[DllImport("Kernel32.dll")] 
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

function Show-Console
{
	$ConsoleHandle = [Native.WinAPI]::GetConsoleWindow()
	[Native.WinAPI]::ShowWindow($ConsoleHandle, 5) | Out-Null
}

function Hide-Console
{
	$ConsoleHandle = [Native.WinAPI]::GetConsoleWindow()
	[Native.WinAPI]::ShowWindow($ConsoleHandle, 0) | Out-Null
}
###############################################################