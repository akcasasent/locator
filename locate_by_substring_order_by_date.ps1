param (
    [Parameter(Mandatory=$true)]
    [string]$substring,
    
    [Parameter(Mandatory=$false)]
    [string]$outputPath = ""
)

# Get current date in format YYYYMMDD
$date = Get-Date -Format "yyyyMMdd"

# Generate the default filename
$defaultFileName = "${date}_filelist_by_date_generated_${substring}.txt"

# Handle output path
if ([string]::IsNullOrEmpty($outputPath)) {
    # If no path provided, use current directory
    $outputFile = Join-Path -Path $PWD -ChildPath $defaultFileName
}
elseif (Test-Path -Path $outputPath -PathType Container) {
    # If provided path is a directory, use it with the default filename
    $outputFile = Join-Path -Path $outputPath -ChildPath $defaultFileName
}
else {
    # If provided path includes a filename, use it as is
    $outputFile = $outputPath
}

# Ensure the directory exists
$outputDir = Split-Path -Path $outputFile -Parent
if (-not (Test-Path -Path $outputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Write header to the output file
"File List - Substring: '$substring'" | Out-File $outputFile
"Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $outputFile -Append
"" | Out-File $outputFile -Append
"Path | Size (bytes) | Creation Date" | Out-File $outputFile -Append
"-" * 80 | Out-File $outputFile -Append

Get-ChildItem -Recurse -File | 
  Where-Object { $_.Name -like "*$substring*" } |
  Select-Object FullName, Length, CreationTime |
  ForEach-Object { 
    "{0} | {1} | {2}" -f $_.FullName, $_.Length, $_.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
  } |
  Out-File $outputFile -Append

Write-Host "File list with substring '$substring' has been saved to '$outputFile'"