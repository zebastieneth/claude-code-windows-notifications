# Claude Code Windows Notifications - Uninstaller
# Run: powershell -ExecutionPolicy Bypass -File uninstall.ps1

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

Write-Host ""
Write-Host "  Uninstalling Claude Code Windows Notifications..." -ForegroundColor Yellow
Write-Host ""

# Remove files
$files = @("notify.ps1", "focus-terminal.ps1", "focus-terminal.vbs", "notification-icon.png", "notification-sound.mp3")
foreach ($file in $files) {
    $path = Join-Path $ClaudeDir $file
    if (Test-Path $path) { Remove-Item $path -Force; Write-Host "  Removed $file" }
}

# Remove protocol
if (Test-Path 'HKCU:\Software\Classes\claude-focus') {
    Remove-Item 'HKCU:\Software\Classes\claude-focus' -Recurse -Force
    Write-Host "  Removed claude-focus: protocol"
}

# Remove hook from settings
$settingsPath = Join-Path $ClaudeDir "settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    if ($settings.PSObject.Properties['hooks'] -and $settings.hooks.PSObject.Properties['Notification']) {
        $settings.hooks.PSObject.Properties.Remove('Notification')
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Force
        Write-Host "  Removed Notification hook from settings"
    }
}

Write-Host ""
Write-Host "  Uninstall complete!" -ForegroundColor Green
Write-Host ""
