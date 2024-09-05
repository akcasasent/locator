# Configuration variables
$currentDate = Get-Date
$daysToKeep = 120
$cutoffDate = $currentDate.AddDays(-$daysToKeep)
$sizeCutoffGB = 1
$sizeCutoffBytes = $sizeCutoffGB * 1GB
$imageFileExtensions = @('.tiff','.tif','.jpg','.jpeg','.png','.gif','.bmp','.raw','.cr2','.nef','.arw','.dng','.psd','.ai','.eps','.mcd','.qptiff','.ims','.sbd','.slx')

# Path configurations
$baseLogPath = 'C:\Users\scopecore\Desktop\_scans\logs'
$outputFileName = "LargeOldImageFilesReport_$($currentDate.ToString('yyyyMMdd')).csv"
$logFileName = "LargeOldImageFilesScript_$($currentDate.ToString('yyyyMMdd')).log"
$outputFile = Join-Path -Path $baseLogPath -ChildPath $outputFileName
$logFile = Join-Path -Path $baseLogPath -ChildPath $logFileName

# System information
$machineName = $env:COMPUTERNAME

# Define functions
# Gets all the Drives that on computer (not mounted but hardware)
function Get-AllDrives {
    Get-WmiObject Win32_LogicalDisk | 
    Where-Object { $_.DriveType -eq 3 } | 
    Select-Object -ExpandProperty DeviceID
}

# Sets up to write the log to the correct place
function Write-Log {
    param([string]$Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

# Gets the large image files 
function Get-LargeOldImageFiles {
    param (
        [string]$Drive,
        [datetime]$CutoffDate,
        [long]$MinSize,
        [string[]]$Extensions
    )

    $files = Get-ChildItem -Path $Drive -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { 
            $_.Length -ge $MinSize -and 
            $_.LastWriteTime -le $CutoffDate -and 
            $Extensions -contains $_.Extension.ToLower()
        } |
        Select-Object FullName, Name, Extension, Length,
            @{Name="SizeGB";Expression={[math]::Round($_.Length / 1GB, 2)}},
            LastWriteTime, 
            @{Name="AgeInDays";Expression={[math]::Round((New-TimeSpan -Start $_.LastWriteTime -End $currentDate).TotalDays, 0)}}

    return $files
}

# Get all drives
$allDrives = Get-AllDrives

# Initialize array to store large, old image files
$largeOldImageFiles = @()

# Process each drive
foreach ($drive in $allDrives) {
    Write-Log "Processing drive $drive..."
    $largeOldImageFiles += Get-LargeOldImageFiles -Drive $drive -CutoffDate $cutoffDate -MinSize $sizeCutoffBytes -Extensions $imageFileExtensions | Where-Object { $_ -ne $null }
}

# Write a summary to the log file
Write-Log "Processing complete. Total large old image files found: $($largeOldImageFiles.Count)"

# Export large, old image files to CSV
$largeOldImageFiles | Export-Csv -Path $outputFile -NoTypeInformation

# Calculate total space and space taken by large, old image files
$totalSpace = 0
$totalFreeSpace = 0
$largeOldImageFilesSize = ($largeOldImageFiles | Measure-Object -Property Length -Sum).Sum

foreach ($drive in $allDrives) {
    $driveInfo = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$drive'"
    $totalSpace += $driveInfo.Size
    $totalFreeSpace += $driveInfo.FreeSpace
}

$totalSpaceGB = [math]::Round($totalSpace / 1GB, 2)
$totalFreeSpaceGB = [math]::Round($totalFreeSpace / 1GB, 2)
$largeOldImageFilesSizeGB = [math]::Round($largeOldImageFilesSize / 1GB, 2)

# Get file extension statistics
$extensionStats = $largeOldImageFiles | Group-Object -Property Extension | 
    Select-Object @{Name="Extension";Expression={$_.Name}}, Count, 
    @{Name="TotalSizeGB";Expression={[math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum / 1GB, 2)}} |
    Sort-Object TotalSizeGB -Descending

# Prepare report content
$reportContent = @"
Weekly Large Old Image Files Report

Machine Information:
Machine Name: $machineName

Large Old Image Files Report saved to: $outputFile

Space Summary:
Total Space on All Drives: $totalSpaceGB GB
Free Space on All Drives: $totalFreeSpaceGB GB
Space Taken by Large Image Files (>= ${sizeCutoffGB}GB) Older Than $daysToKeep Days: $largeOldImageFilesSizeGB GB
Total Large Old Image Files Found: $($largeOldImageFiles.Count)

Date Range: Older than $($cutoffDate.ToString('yyyy-MM-dd'))
Minimum File Size: ${sizeCutoffGB}GB

File Extension Statistics:
$($extensionStats | ForEach-Object { "$($_.Extension): $($_.Count) files, $($_.TotalSizeGB) GB" } | Out-String)

Image File Extensions Checked: $($imageFileExtensions -join ', ')
"@

# Write report content to log file
Write-Log "$reportContent"

# Display report content in console
Write-Host "$reportContent"