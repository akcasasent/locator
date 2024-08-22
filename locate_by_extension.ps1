param (
    [Parameter(Mandatory=$true)]
    [string]$extension,
    
    [Parameter(Mandatory=$false)]
    [string]$outputPath = ""
)

# Ensure the extension starts with a dot
if (-not $extension.StartsWith(".")) {
    $extension = "." + $extension
}

# Remove the dot for the filename
$cleanExtension = $extension.TrimStart(".")

# Get current date in format YYYYMMDD
$date = Get-Date -Format "yyyyMMdd"

# Generate the default filename
$defaultFileName = "${date}_filelist_by_${cleanExtension}.txt"

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

Get-ChildItem -Recurse -File | 
  Where-Object { $_.Extension -eq $extension } |
  Select-Object FullName, Length |
  ForEach-Object { "$($_.FullName) $($_.Length)" } |
  Out-File $outputFile

Write-Host "File list with extension '$extension' has been saved to '$outputFile'"
