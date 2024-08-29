# Script to check the health and SMART attributes of all drives on a Windows system and send email alerts

# Ensure the script runs with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as an Administrator."
    exit 1
}

# SMTP Configuration
$smtpServer = "smtp.example.com"
$smtpPort = 587
$smtpUser = "your-email@example.com"
$smtpPassword = "your-email-password"
$toEmail = "recipient@example.com"
$fromEmail = "your-email@example.com"

# Get the machine name
$machineName = $env:COMPUTERNAME

# Initialize report variables
$subject = "Drive Health Check Report for $machineName"
$issuesFound = $false
$issueDetails = ""
$detailedLog = ""

# Get all physical disks and their health status
$physicalDisks = Get-PhysicalDisk
$volumes = Get-Volume

foreach ($disk in $physicalDisks) {
    try {
        $diskInfo = @{
            'MachineName' = $machineName
            'DeviceID' = $disk.DeviceID
            'FriendlyName' = $disk.FriendlyName
            'HealthStatus' = $disk.HealthStatus
            'OperationalStatus' = $disk.OperationalStatus
        }

        # Get SMART attributes
        $smartData = Get-StorageReliabilityCounter -PhysicalDisk $disk

        $diskInfo['Temperature'] = $smartData.Temperature
        $diskInfo['TotalReadErrors'] = $smartData.ReadErrorsTotal
        $diskInfo['TotalWriteErrors'] = $smartData.WriteErrorsTotal
        $diskInfo['WearLevel'] = $smartData.Wear

        # Find the volume associated with this disk
        $volume = $volumes | Where-Object { $_.DriveLetter -eq $disk.DeviceID }

        if ($volume) {
            $diskInfo['DriveLetter'] = $volume.DriveLetter
            $diskInfo['FileSystem'] = $volume.FileSystem
            $diskInfo['Size(GB)'] = [math]::round($volume.Size / 1GB, 2)
            $diskInfo['FreeSpace(GB)'] = [math]::round($volume.SizeRemaining / 1GB, 2)
        }

        # Log detailed information
        $detailedLog += "Machine: $($machineName)`n"
        $detailedLog += "Disk: $($disk.FriendlyName)`n"
        $detailedLog += "DeviceID: $($disk.DeviceID)`n"
        $detailedLog += "Health Status: $($disk.HealthStatus)`n"
        $detailedLog += "Operational Status: $($disk.OperationalStatus)`n"
        $detailedLog += "Temperature: $($smartData.Temperature)`n"
        $detailedLog += "Total Read Errors: $($smartData.ReadErrorsTotal)`n"
        $detailedLog += "Total Write Errors: $($smartData.WriteErrorsTotal)`n"
        $detailedLog += "Wear Level: $($smartData.Wear)`n"
        $detailedLog += "Drive Letter: $($volume.DriveLetter)`n"
        $detailedLog += "File System: $($volume.FileSystem)`n"
        $detailedLog += "Size (GB): $([math]::round($volume.Size / 1GB, 2))`n"
        $detailedLog += "Free Space (GB): $([math]::round($volume.SizeRemaining / 1GB, 2))`n`n"

        # Check for issues
        if ($disk.HealthStatus -ne 'Healthy' -or $smartData.ReadErrorsTotal -gt 0 -or $smartData.WriteErrorsTotal -gt 0 -or $smartData.Wear -gt 0) {
            $issuesFound = $true
            $issueDetails += "Issue found on $machineName - Disk: $($disk.FriendlyName) - Health: $($disk.HealthStatus), Read Errors: $($smartData.ReadErrorsTotal), Write Errors: $($smartData.WriteErrorsTotal), Wear Level: $($smartData.Wear)`n"
        }
    } catch {
        Write-Host "Failed to retrieve SMART data for disk: $($disk.DeviceID)"
    }
}

# Output the detailed log to a file
$detailedLogFilePath = "C:\Path\To\DetailedDriveReport_$machineName.txt"
$detailedLog | Out-File -FilePath $detailedLogFilePath

# Send email if issues are found
if ($issuesFound) {
    $subject = "ALERT: Drive Health Issues Detected on $machineName"
    $body = "Drive Health Check Report for $machineName:`n`n$issueDetails"
} else {
    $body = "Drive Health Check Report for $machineName: All drives are healthy."
}

# Send the email
Send-MailMessage -SmtpServer $smtpServer -Port $smtpPort -Credential (New-Object System.Management.Automation.PSCredential($smtpUser, (ConvertTo-SecureString $smtpPassword -AsPlainText -Force))) -From $fromEmail -To $toEmail -Subject $subject -Body $body -BodyAsHtml
