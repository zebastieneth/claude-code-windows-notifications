$env:CLAUDE_NOTIFY_TYPE = "idle_prompt"
& (Join-Path $env:USERPROFILE ".claude\notify.ps1") -Message "Claude has finished working"
