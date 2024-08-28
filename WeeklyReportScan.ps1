# Set the schedule for weekly execution
$trigger = New-JobTrigger -Weekly -DaysOfWeek Monday -At 3AM

# Register the scheduled job to run weekly
Register-ScheduledJob -Name "WeeklyFileReportAndCleanup" -Trigger $trigger -ScriptBlock {
    # Get machine name and IP address
    $machineName = $env:COMPUTERNAME
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

    # Define the output drive for storing reports (change this to your preferred drive letter)
    $outputDrive = "D:"

    # Initialize error logs
    $duplicateErrorLogPath = "$outputDrive\${machineName}_DuplicateErrorLog_$(Get-Date -Format 'yyyyMMdd').txt"
    $imageErrorLogPath = "$outputDrive\${machineName}_ImageErrorLog_$(Get-Date -Format 'yyyyMMdd').txt"
    $duplicateErrorLog = @()
    $imageErrorLog = @()

    # Part 1: Weekly Duplicate File Report
    $duplicates = @()
    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        try {
            $files = Get-ChildItem -Path $drive.Root -Recurse -File -ErrorAction Stop
        } catch {
            $duplicateErrorLog += "Error accessing drive $($drive.Root): $_"
            continue
        }

        $groups = $files | Group-Object Name, Length
        $potentialDuplicates = $groups | Where-Object { $_.Count -gt 1 }

        foreach ($group in $potentialDuplicates) {
            $fileGroup = $group.Group
            for ($i = 0; $i -lt $fileGroup.Count - 1; $i++) {
                for ($j = $i + 1; $j -lt $fileGroup.Count; $j++) {
                    try {
                        if ((Get-FileHash $fileGroup[$i].FullName).Hash -eq (Get-FileHash $fileGroup[$j].FullName).Hash) {
                            $duplicates += [PSCustomObject]@{
                                FileName = $fileGroup[$i].Name
                                Path1 = $fileGroup[$i].FullName
                                Path2 = $fileGroup[$j].FullName
                            }
                        }
                    } catch {
                        $duplicateErrorLog += "Error comparing files $($fileGroup[$i].FullName) and $($fileGroup[$j].FullName): $_"
                    }
                }
            }
        }
    }

    $duplicateReportPath = "$outputDrive\${machineName}_DuplicateFileReport_$(Get-Date -Format 'yyyyMMdd').csv"
    $duplicates | Export-Csv -Path $duplicateReportPath -NoTypeInformation

    # Write duplicate error log to file
    $duplicateErrorLog | Out-File -FilePath $duplicateErrorLogPath

    # Part 2: Large Image File Scan
    $largeImageFiles = @()
    $imageExtensions = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff")

    foreach ($drive in $drives) {
        try {
            $files = Get-ChildItem -Path $drive.Root -Recurse -File -ErrorAction Stop |
                     Where-Object { $imageExtensions -contains $_.Extension }
        } catch {
            $imageErrorLog += "Error accessing drive $($drive.Root) for image scan: $_"
            continue
        }

        foreach ($file in $files) {
            try {
                $shell = New-Object -COMObject Shell.Application
                $folder = $shell.Namespace($file.DirectoryName)
                $item = $folder.ParseName($file.Name)
                
                $dimensions = $folder.GetDetailsOf($item, 31)
                if ($dimensions -match '(\d+)\s*x\s*(\d+)') {
                    $width = [int]$Matches[1]
                    $height = [int]$Matches[2]
                    
                    if ($width -gt 1920 -or $height -gt 1080) {
                        $largeImageFiles += [PSCustomObject]@{
                            FileName = $file.Name
                            Path = $file.FullName
                            Size = $file.Length
                            Dimensions = $dimensions
                        }
                    }
                }
            } catch {
                $imageErrorLog += "Error processing image file $($file.FullName): $_"
            }
        }
    }

    $largeImageReportPath = "$outputDrive\${machineName}_LargeImageReport_$(Get-Date -Format 'yyyyMMdd').csv"
    $largeImageFiles | Export-Csv -Path $largeImageReportPath -NoTypeInformation

    # Write image error log to file
    $imageErrorLog | Out-File -FilePath $imageErrorLogPath

    # Generate summary report
    $summaryReportPath = "$outputDrive\${machineName}_SummaryReport_$(Get-Date -Format 'yyyyMMdd').txt"
    $summaryContent = @"
Weekly File Report and Cleanup Summary
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Machine Name: $machineName
IP Address: $ipAddress

1. Duplicate File Report
   - Total duplicate files found: $($duplicates.Count)
   - Report location: $duplicateReportPath
   - Error log location: $duplicateErrorLogPath
   - Total errors in duplicate scan: $($duplicateErrorLog.Count)

2. Large Image File Report
   - Total large image files found: $($largeImageFiles.Count)
   - Report location: $largeImageReportPath
   - Error log location: $imageErrorLogPath
   - Total errors in image scan: $($imageErrorLog.Count)

Please review the detailed reports and error logs for more information.
"@

    $summaryContent | Out-File -FilePath $summaryReportPath

    # Optional: Email notification
    # Send-MailMessage -From "sender@example.com" -To "recipient@example.com" -Subject "Weekly File Report and Cleanup Summary - $machineName" -Body $summaryContent -Attachments $duplicateReportPath,$largeImageReportPath,$summaryReportPath,$duplicateErrorLogPath,$imageErrorLogPath -SmtpServer "smtp.example.com"

    # Check for specific running tasks
    $specificTasks = @("Task1", "Task2", "Task3") # Replace with actual task names
    $runningTasks = Get-Process | Where-Object { $specificTasks -contains $_.ProcessName }

    if ($runningTasks.Count -eq 0) {
        # No specific tasks are running, proceed with restart
        Restart-Computer -Force
    } else {
        # Specific tasks are running, prompt user for restart
        $promptMessage = "The following tasks are still running:`n"
        $runningTasks | ForEach-Object { $promptMessage += "- $($_.ProcessName)`n" }
        $promptMessage += "`nDo you want to restart the computer? (Y/N)"

        $decision = $null
        $job = Start-Job -ScriptBlock {
            Add-Type -AssemblyName System.Windows.Forms
            $result = [System.Windows.Forms.MessageBox]::Show($args[0], "Restart Computer?", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            return $result
        } -ArgumentList $promptMessage

        # Wait for 15 minutes or until the user responds
        $null = Wait-Job $job -Timeout 900

        if ($job.State -eq 'Completed') {
            $decision = Receive-Job $job
            Remove-Job $job

            if ($decision -eq 'Yes') {
                Restart-Computer -Force
            }
        } else {
            # User didn't respond within 15 minutes
            Stop-Job $job
            Remove-Job $job
        }
    }
}
