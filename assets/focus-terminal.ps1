# Focus the Windows Terminal window
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinFocus {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

$wtProcess = Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($wtProcess) {
    $hwnd = $wtProcess.MainWindowHandle
    if ($hwnd -ne [IntPtr]::Zero) {
        [WinFocus]::ShowWindow($hwnd, 9)
        [WinFocus]::SetForegroundWindow($hwnd)
    }
}
