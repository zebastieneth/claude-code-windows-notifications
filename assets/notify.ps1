# Claude Code notification script
# Plays sound + shows Windows toast notification with smart features:
# - Different titles/emojis per notification type
# - Project folder name in title (helps with multiple tabs)
# - 3-second cooldown to prevent spam
# - Suppresses when terminal is already focused
# - Flashes taskbar icon
# - Click toast to focus terminal

param(
    [string]$Title = "Claude Code",
    [string]$Message = "Needs your attention"
)

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

# Read message from stdin (hook input) if available
$NotificationType = ""
try {
    $input_data = [Console]::In.ReadToEnd() | ConvertFrom-Json
    if ($input_data.title) { $Title = $input_data.title }
    if ($input_data.message) { $Message = $input_data.message }
    if ($input_data.notification_type) { $NotificationType = $input_data.notification_type }
} catch {}

# Get project folder name from current working directory
$projectName = Split-Path (Get-Location).Path -Leaf

# Cooldown: skip if last notification was less than 3 seconds ago
$cooldownFile = "$env:TEMP\claude-notify-last.txt"
$now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
if (Test-Path $cooldownFile) {
    $last = [long](Get-Content $cooldownFile -ErrorAction SilentlyContinue)
    if (($now - $last) -lt 3000) { exit 0 }
}
$now | Set-Content $cooldownFile -Force

# Customize title based on notification type
switch ($NotificationType) {
    "permission_prompt"  { $Title = "$([char]0x26A1) Permission Required" }
    "idle_prompt"        { $Title = "$([char]0x2705) Task Complete" }
    "auth_success"       { $Title = "$([char]0xD83D)$([char]0xDD11) Authentication Successful" }
    "elicitation_dialog" { $Title = "$([char]0x2734)$([char]0xFE0F) Input Needed" }
}

# Append project name to title
if ($projectName) { $Title = "$Title - $projectName" }

# Check if Windows Terminal is already the foreground window
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinFocus {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

    [StructLayout(LayoutKind.Sequential)]
    public struct FLASHWINFO {
        public uint cbSize;
        public IntPtr hwnd;
        public uint dwFlags;
        public uint uCount;
        public uint dwTimeout;
    }
}
"@

$wtProcess = Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue | Select-Object -First 1
$alreadyFocused = $false

if ($wtProcess) {
    $hwnd = $wtProcess.MainWindowHandle
    $foreground = [WinFocus]::GetForegroundWindow()
    $alreadyFocused = ($hwnd -eq $foreground) -and ($hwnd -ne [IntPtr]::Zero)
}

# If terminal is already focused, skip notification and sound
if ($alreadyFocused) { exit 0 }

# Flash taskbar icon
if ($wtProcess -and $wtProcess.MainWindowHandle -ne [IntPtr]::Zero) {
    $flash = New-Object WinFocus+FLASHWINFO
    $flash.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($flash)
    $flash.hwnd = $wtProcess.MainWindowHandle
    $flash.dwFlags = 3  # FLASHW_ALL (flash both caption and taskbar)
    $flash.uCount = 3
    $flash.dwTimeout = 0
    [WinFocus]::FlashWindowEx([ref]$flash) | Out-Null
}

# Preload sound so it's ready to play instantly
Add-Type -AssemblyName PresentationCore
$mp = New-Object System.Windows.Media.MediaPlayer
$soundFile = Join-Path $ClaudeDir "notification-sound.mp3"
$mp.Open([Uri]$soundFile)
Start-Sleep -Milliseconds 300

# Show Windows toast notification with auto-dismiss
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null

$iconPath = Join-Path $ClaudeDir "notification-icon.png"
$template = @"
<toast duration="short" activationType="protocol" launch="claude-focus:">
    <visual>
        <binding template="ToastGeneric">
            <image placement="appLogoOverride" hint-crop="circle" src="$iconPath"/>
            <text>$Title</text>
            <text>$Message</text>
        </binding>
    </visual>
    <audio silent="true"/>
</toast>
"@

$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml($template)

$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)

# Play sound in sync with toast
$mp.Play()
Start-Sleep -Seconds 2
