$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Users\scopecore\Desktop\_scans\scripts\RunWeeklyScripts.ps1"
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 5am
$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun
Register-ScheduledTask -TaskName "WeeklyMaintenanceScripts" -Action $Action -Trigger $Trigger -Settings $Settings -User "SYSTEM" -RunLevel Highest