# Set script parameters
param (
    [int]$DaysBack = 30,
    [string]$OutputFolder = "$env:USERPROFILE\Desktop",
    [long]$MinFileSize = 1GB,
    [string]$CredentialFile = "$env:USERPROFILE\EmailCredential.xml"
)

# Email settings
$smtpServer = "your.smtp.server"
$smtpPort = 587
$fromAddress = "sender@example.com"
$toAddress = "recipient@example.com"
$subjectPrefix = "Weekly Large Old Image Files Report -"

# Define image file extensions to check
$imageExtensions = @('.tiff', '.tif', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.raw', '.cr2', '.nef', '.arw', '.dng', '.psd', '.ai', '.eps', '.mcd', '.qptiff', '.ims', '.sbd','.slx')

# Function to get all drives
function Get-AllDrives {
    Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
}

# Function to get large, old image files
function Get-LargeOldImageFiles {
    param (
        [string]$Drive,
        [datetime]$CutoffDate,
        [long]$MinSize,
        [array]$Extensions
    )
    
    Get-ChildItem -Path $Drive -Recurse -File -ErrorAction SilentlyContinue | 
        Where-Object { 
            $_.LastWriteTime -lt $CutoffDate -and 
            $_.Length -ge $MinSize -and 
            $Extensions -contains $_.Extension.ToLower()
        } |
        Select-Object FullName, LastWriteTime, Length, @{Name="Extension";Expression={$_.Extension.ToLower()}}
}

# Create the WeeklyCleanupAndReport script
$weeklyScript = @"
# Set variables
`$currentDate = Get-Date
`$cutoffDate = `$currentDate.AddDays(-$DaysBack)
`$outputFile = Join-Path -Path '$OutputFolder' -ChildPath "LargeOldImageFilesReport_`$(`$currentDate.ToString('yyyyMMdd')).csv"

# Get machine name and IP address
`$machineName = `$env:COMPUTERNAME
`$ipAddress = (Get-NetIPAddress | Where-Object {`$_.AddressFamily -eq 'IPv4' -and `$_.PrefixOrigin -eq 'Dhcp'}).IPAddress

# Get all drives
`$allDrives = Get-AllDrives

# Initialize array to store large, old image files
`$largeOldImageFiles = @()

# Process each drive
foreach (`$drive in `$allDrives) {
    Write-Host "Processing drive `$drive..."
    `$largeOldImageFiles += Get-LargeOldImageFiles -Drive `$drive -CutoffDate `$cutoffDate -MinSize $MinFileSize -Extensions $imageExtensions
}

# Export large, old image files to CSV
`$largeOldImageFiles | Export-Csv -Path `$outputFile -NoTypeInformation

# Calculate total space and space taken by large, old image files
`$totalSpace = 0
`$totalFreeSpace = 0
`$largeOldImageFilesSize = (`$largeOldImageFiles | Measure-Object -Property Length -Sum).Sum

foreach (`$drive in `$allDrives) {
    `$driveInfo = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='`$drive'"
    `$totalSpace += `$driveInfo.Size
    `$totalFreeSpace += `$driveInfo.FreeSpace
}

`$totalSpaceGB = [math]::Round(`$totalSpace / 1GB, 2)
`$totalFreeSpaceGB = [math]::Round(`$totalFreeSpace / 1GB, 2)
`$largeOldImageFilesSizeGB = [math]::Round(`$largeOldImageFilesSize / 1GB, 2)

# Get file extension statistics
`$extensionStats = `$largeOldImageFiles | Group-Object -Property Extension | 
    Select-Object @{Name="Extension";Expression={`$_.Name}}, Count, 
    @{Name="TotalSizeGB";Expression={[math]::Round((`$_.Group | Measure-Object -Property Length -Sum).Sum / 1GB, 2)}} |
    Sort-Object TotalSizeGB -Descending

# Prepare email body
`$emailBody = @"
Weekly Large Old Image Files Report

Machine Information:
Machine Name: `$machineName
IP Address: `$ipAddress

Large Old Image Files Report saved to: `$outputFile

Space Summary:
Total Space on All Drives: `$totalSpaceGB GB
Free Space on All Drives: `$totalFreeSpaceGB GB
Space Taken by Large Image Files (>= 1GB) Older Than $DaysBack Days: `$largeOldImageFilesSizeGB GB
Total Large Old Image Files Found: `$(`$largeOldImageFiles.Count)

Date Range: Older than `$(`$cutoffDate.ToString('yyyy-MM-dd'))
Minimum File Size: 1GB

File Extension Statistics:
$(`$extensionStats | ForEach-Object { "`$(`$_.Extension): `$(`$_.Count) files, `$(`$_.TotalSizeGB) GB" } | Out-String)

Image File Extensions Checked: $($imageExtensions -join ', ')
"@

# Load the credential
`$credential = Import-Clixml -Path '$CredentialFile'

# Send email
`$smtpClient = New-Object Net.Mail.SmtpClient(`$smtpServer, `$smtpPort)
`$smtpClient.EnableSsl = `$true
`$smtpClient.Credentials = `$credential

`$mailMessage = New-Object System.Net.Mail.MailMessage(`$fromAddress, `$toAddress, `$subjectPrefix + " `$machineName", `$emailBody)
`$mailMessage.Attachments.Add(`$outputFile)
`$smtpClient.Send(`$mailMessage)

Write-Host "Report generated and email sent."
"@

# Save the WeeklyCleanupAndReport script
$weeklyScriptPath = "$env:TEMP\WeeklyLargeOldImageFilesReport.ps1"
$weeklyScript | Out-File -FilePath $weeklyScriptPath -Encoding UTF8

# Create a new scheduled task action
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$weeklyScriptPath`""

# Create a trigger for every Friday at 9:00 AM
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At 9am

# Set the task settings
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd

# Create the scheduled task
$taskName = "Weekly Large Old Image Files Report"
$description = "Checks for large old image files (>= 1GB) across all drives, generates a report, and emails it every Friday at 9:00 AM"

# Register the scheduled task
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description $description -Settings $settings -User "SYSTEM"

Write-Host "Scheduled task created successfully."

# Create the credential file if it doesn't exist
if (-not (Test-Path $CredentialFile)) {
    $emailCredential = Get-Credential -Message "Enter the email account credentials"
    $emailCredential | Export-Clixml -Path $CredentialFile
    Write-Host "Credential file created at $CredentialFile"
}
