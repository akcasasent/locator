param (
    [Parameter(Mandatory=$true)]
    [string]$extension,
    
    [Parameter(Mandatory=$false)]
    [string]$outputFile = ""
)

# Ensure the extension starts with a dot
if (-not $extension.StartsWith(".")) {
    $extension = "." + $extension
}

# Remove the dot for the filename
$cleanExtension = $extension.TrimStart(".")

# Get current date in format YYYYMMDD
$date = Get-Date -Format "yyyyMMdd"

# Set default output file name if not provided
if ([string]::IsNullOrEmpty($outputFile)) {
    $outputFile = "${date}_filelist_by_${cleanExtension}.txt"
}

Get-ChildItem -Recurse -File | 
  Where-Object { $_.Extension -eq $extension } |
  Select-Object FullName, Length |
  ForEach-Object { "$($_.FullName) $($_.Length)" } |
  Out-File $outputFile

Write-Host "File list with extension '$extension' has been saved to '$outputFile'"
