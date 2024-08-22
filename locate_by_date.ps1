param (
    [string]$Path = "C:\",
    [string]$Extension = "*",
    [int]$DaysBack = 365,
    [long]$MinSize = 0,
    [long]$MaxSize = [long]::MaxValue,
    [string]$OutputFolder = $PSScriptRoot
)

$currentDate = Get-Date
$cutoffDate = $currentDate.AddDays(-$DaysBack)

# Create a default filename if not provided
$defaultFileName = "FileList_{0:yyyyMMdd}_Back{1}d_{2}.csv" -f $currentDate, $DaysBack, $Extension.TrimStart("*.")
$outputPath = Join-Path $OutputFolder $defaultFileName

# Ensure output directory exists
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$files = Get-ChildItem -Path $Path -Recurse -File -Include "*$Extension" | 
    Where-Object { 
        $_.LastWriteTime -ge $cutoffDate -and 
        $_.Length -ge $MinSize -and 
        $_.Length -le $MaxSize 
    } | 
    Select-Object FullName, LastWriteTime, Length

$files | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host "File list has been exported to $outputPath"
Write-Host "Total files found: $($files.Count)"
