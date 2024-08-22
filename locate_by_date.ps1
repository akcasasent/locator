param (
    [string]$Path = "C:\",
    [string]$Extension = "*",
    [int]$DaysBackNewest = 365,
    [int]$DaysBackOldest = [int]::MaxValue,
    [long]$MinSize = 0,
    [long]$MaxSize = [long]::MaxValue,
    [string]$OutputFolder = $PSScriptRoot
)

$currentDate = Get-Date
$newestDate = $currentDate.AddDays(-$DaysBackNewest)
$oldestDate = $currentDate.AddDays(-$DaysBackOldest)

# Create a default filename
$defaultFileName = "FileList_{0:yyyyMMdd}_Back{1}to{2}d_{3}.csv" -f $currentDate, $DaysBackNewest, $DaysBackOldest, $Extension.TrimStart("*.")
$outputPath = Join-Path $OutputFolder $defaultFileName

# Ensure output directory exists
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$files = Get-ChildItem -Path $Path -Recurse -File -Include "*$Extension" | 
    Where-Object { 
        $_.LastWriteTime -le $newestDate -and 
        $_.LastWriteTime -ge $oldestDate -and 
        $_.Length -ge $MinSize -and 
        $_.Length -le $MaxSize 
    } | 
    Select-Object FullName, LastWriteTime, Length

$files | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host "File list has been exported to $outputPath"
Write-Host "Total files found: $($files.Count)"
Write-Host "Date range: From $($oldestDate.ToString('yyyy-MM-dd')) to $($newestDate.ToString('yyyy-MM-dd'))"
