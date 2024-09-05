# RunWeeklyScripts.ps1

# Set the base path for all scripts
$scriptPath = "C:\Users\scopecore\Desktop\_scans\scripts"

# Function to check if specific processes are running
function Are-CriticalProcessesRunning {
    $processesToCheck = @("Visiopharm", "SAW", "Rstudio", "SCiLS", "rsync")
    $runningProcesses = @()

    foreach ($process in $processesToCheck) {
        if (Get-Process $process -ErrorAction SilentlyContinue) {
            $runningProcesses += $process
        }
    }

    if ($runningProcesses.Count -gt 0) {
        Write-Output "The following critical processes are still running: $($runningProcesses -join ', ')"
        return $true
    } else {
        return $false
    }
}

# Run the first script
Write-Output "Starting WeeklyCleanupAndReport..."
& "$scriptPath\WeeklyCleanupAndReport.ps1"
$cleanupExitCode = $LASTEXITCODE

# Run the second script regardless of the first script's outcome
Write-Output "Starting Check-DriveHealth..."
& "$scriptPath\Check-DriveHealth.ps1"
$driveHealthExitCode = $LASTEXITCODE

# Check if both scripts completed successfully
if ($cleanupExitCode -eq 0 -and $driveHealthExitCode -eq 0) {
    Write-Output "Both WeeklyCleanupAndReport and Check-DriveHealth completed successfully. Checking if critical processes are running..."
    
    # Check if critical processes are not running
    if (-not (Are-CriticalProcessesRunning)) {
        Write-Output "No critical processes are running. Scheduling restart..."
        
        # Schedule restart for 5 minutes from now
        $restartTime = (Get-Date).AddMinutes(5)
        
        # Create a scheduled task to restart the computer
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command Restart-Computer -Force"
        $trigger = New-ScheduledTaskTrigger -Once -At $restartTime
        Register-ScheduledTask -TaskName "RestartAfterMaintenance" -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest
        
        Write-Output "Restart scheduled for $restartTime"
    } else {
        Write-Output "Critical processes are still running. Restart not scheduled."
    }
} else {
    if ($cleanupExitCode -ne 0) {
        Write-Error "WeeklyCleanupAndReport failed with exit code $cleanupExitCode."
    }
    if ($driveHealthExitCode -ne 0) {
        Write-Error "Check-DriveHealth failed with exit code $driveHealthExitCode."
    }
    Write-Error "One or both scripts failed. Restart will not be scheduled."
}