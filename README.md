# Claude Code Windows Notifications

Native Windows toast notifications for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI.

Never miss a prompt or task completion again — get notified with sound, toast, and taskbar flash when Claude needs your attention.

## Features

- **Toast notifications** with custom icon and sound
- **Smart titles** with emoji per notification type:
  - ⚡ Permission Required
  - ✅ Task Complete
  - 🔑 Authentication Successful
  - ✴️ Input Needed
- **Project name in title** — know which tab needs attention when running multiple sessions
- **Click to focus** — click the toast to bring Windows Terminal to the foreground
- **Taskbar flash** — orange flash on the taskbar icon
- **3-second cooldown** — prevents notification spam
- **Auto-suppress** — no notification when terminal is already focused

## Install

```powershell
git clone https://github.com/YOUR_USERNAME/claude-code-windows-notifications
cd claude-code-windows-notifications
powershell -ExecutionPolicy Bypass -File install.ps1
```

That's it! The installer:
1. Copies notification scripts and assets to `~/.claude/`
2. Registers a `claude-focus:` protocol for click-to-focus
3. Adds the Notification hook to your Claude Code settings

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

## Customize

### Change the notification sound
Replace `assets/notification-sound.mp3` with your own `.mp3` file and re-run `install.ps1`.

### Change the icon
Replace `assets/notification-icon.png` with your own image and re-run `install.ps1`.

## Requirements

- Windows 10/11
- Windows Terminal
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

## How it works

Claude Code supports [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) — shell commands that run in response to events. This project uses the `Notification` hook to trigger a PowerShell script that shows a Windows toast notification with sound.
