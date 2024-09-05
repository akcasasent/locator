# Ensure the script runs with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as an Administrator."
    exit 1
}

# Set the base log path
$baseLogPath = 'C:\Users\scopecore\Desktop\_scans\logs'

# Get the machine name and current timestamp
$machineName = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Initialize log content
$logContent = "Drive Health Check Report for $machineName`nTimestamp: $timestamp`n`n"

# Get all physical disks and volumes
$physicalDisks = Get-PhysicalDisk
$volumes = Get-Volume

# Check disk status using WMI
$diskStatus = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus

foreach ($disk in $physicalDisks) {
    try {
        $logContent += "=" * 50 + "`n"
        $logContent += "Disk: $($disk.FriendlyName)`n"
        $logContent += "DeviceID: $($disk.DeviceID)`n"
        
        # Find the corresponding WMI status for the disk
        $status = $diskStatus | Where-Object { $_.InstanceName -like "*$($disk.DeviceID)*" }

        if ($status) {
            if ($status.PredictFailure) {
                $logContent += "Health Status: WARNING - Predictive failure detected!`n"
            } else {
                $logContent += "Health Status: OK`n"
            }
        } else {
            $logContent += "Health Status: Unknown (No WMI data available)`n"
        }

        # Operational Status
        $logContent += "Operational Status: $($disk.OperationalStatus)`n"

        # Find the associated volume(s) for this disk
        $partitions = Get-Partition | Where-Object { $_.DiskNumber -eq $disk.DeviceID.Split('\')[-1] }
        
        foreach ($partition in $partitions) {
            # Get the volume associated with the partition
            $volume = $volumes | Where-Object { $_.DriveLetter -eq $partition.DriveLetter }

            if ($volume) {
                $sizeGB = [math]::round($volume.Size / 1GB, 2)
                $freeSpaceGB = [math]::round($volume.SizeRemaining / 1GB, 2)
                $freeSpacePercent = [math]::round(($volume.SizeRemaining / $volume.Size) * 100, 2)

                $logContent += "Drive Letter: $($volume.DriveLetter)`n"
                $logContent += "File System: $($volume.FileSystem)`n"
                $logContent += "Size (GB): $sizeGB`n"
                $logContent += "Free Space (GB): $freeSpaceGB`n"
                $logContent += "Free Space (%): $freeSpacePercent`n"

                # Check for low disk space warning
                if ($freeSpacePercent -lt 10) {
                    $logContent += "WARNING: Less than 10% free space remaining!`n"
                }
            } else {
                $logContent += "No associated volume found for this partition with Drive Letter: $($partition.DriveLetter)`n"
            }
        }

        $logContent += "`n"
    } catch {
        $logContent += "Failed to retrieve data for disk: $($disk.DeviceID)`n"
        $logContent += "Error: $($_.Exception.Message)`n`n"
    }
}

# Create the log file
$logFileName = "${machineName}_DriveHealthCheck_$timestamp.log"
$logFilePath = Join-Path -Path $baseLogPath -ChildPath $logFileName

# Output the log content to the file
$logContent | Out-File -FilePath $logFilePath -Encoding UTF8

Write-Host "Drive health check completed. Log file created at: $logFilePath"