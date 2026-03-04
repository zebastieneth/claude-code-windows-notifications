# Claude Code Windows Notifications - Installer
# Run: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AssetsDir = Join-Path $ScriptDir "assets"

Write-Host ""
Write-Host "  Claude Code Windows Notifications" -ForegroundColor Cyan
Write-Host "  ==================================" -ForegroundColor Cyan
Write-Host ""

# 1. Copy assets to ~/.claude/
Write-Host "[1/4] Copying files to $ClaudeDir..." -ForegroundColor Yellow

if (!(Test-Path $ClaudeDir)) { New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null }

Copy-Item (Join-Path $AssetsDir "notify.ps1") $ClaudeDir -Force
Copy-Item (Join-Path $AssetsDir "focus-terminal.ps1") $ClaudeDir -Force
Copy-Item (Join-Path $AssetsDir "notification-icon.png") $ClaudeDir -Force
Copy-Item (Join-Path $AssetsDir "notification-sound.mp3") $ClaudeDir -Force

# Create focus-terminal.vbs (dynamically with correct path)
$vbsPath = Join-Path $ClaudeDir "focus-terminal.vbs"
$focusPs1 = Join-Path $ClaudeDir "focus-terminal.ps1"
$vbsContent = "CreateObject(""WScript.Shell"").Run ""powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File """"$focusPs1"""""", 0, False"
Set-Content -Path $vbsPath -Value $vbsContent -Force

Write-Host "  Done." -ForegroundColor Green

# 2. Register claude-focus: protocol
Write-Host "[2/4] Registering claude-focus: protocol..." -ForegroundColor Yellow

New-Item -Path 'HKCU:\Software\Classes\claude-focus' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Classes\claude-focus' -Name '(Default)' -Value 'Claude Focus Protocol'
Set-ItemProperty -Path 'HKCU:\Software\Classes\claude-focus' -Name 'URL Protocol' -Value ''
New-Item -Path 'HKCU:\Software\Classes\claude-focus\shell\open\command' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Classes\claude-focus\shell\open\command' -Name '(Default)' -Value "wscript.exe `"$vbsPath`""

Write-Host "  Done." -ForegroundColor Green

# 3. Update Claude Code settings.json
Write-Host "[3/4] Configuring Claude Code hooks..." -ForegroundColor Yellow

$settingsPath = Join-Path $ClaudeDir "settings.json"
$notifyScript = Join-Path $ClaudeDir "notify.ps1"
$hookCommand = "powershell -ExecutionPolicy Bypass -File $($notifyScript -replace '\\','\\')"

$hook = @{
    matcher = ""
    hooks = @(
        @{
            type = "command"
            command = $hookCommand
        }
    )
}

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
} else {
    $settings = [PSCustomObject]@{}
}

# Add hooks property if missing
if (-not $settings.PSObject.Properties['hooks']) {
    $settings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{})
}

# Set Notification hook
$settings.hooks | Add-Member -NotePropertyName 'Notification' -NotePropertyValue @($hook) -Force

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Force

Write-Host "  Done." -ForegroundColor Green

# 4. Test
Write-Host "[4/4] Sending test notification..." -ForegroundColor Yellow

$testInput = '{"notification_type":"idle_prompt","message":"Installation successful!"}'
$testInput | powershell -ExecutionPolicy Bypass -File $notifyScript

Write-Host "  Done." -ForegroundColor Green

Write-Host ""
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "  You should see a test notification now." -ForegroundColor Green
Write-Host ""
Write-Host "  Features:" -ForegroundColor Cyan
Write-Host "    - Toast notifications with custom sound"
Write-Host "    - Emoji titles per notification type"
Write-Host "    - Project folder name in title"
Write-Host "    - Click toast to focus terminal"
Write-Host "    - Taskbar icon flash"
Write-Host "    - 3-second cooldown (no spam)"
Write-Host "    - Auto-suppressed when terminal is focused"
Write-Host ""
