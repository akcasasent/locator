# locator
scripts for locating different files: 

## 1. locate_by_extension.ps1
Useage options for ```locate_by_extension.ps1``` script.
### Use default output location (current directory)
```powershell -ExecutionPolicy Bypass -File locate_by_extension.ps1 -extension pdf```
### Specify only an output directory
```powershell -ExecutionPolicy Bypass -File locate_by_extension.ps1 -extension docx -outputPath "C:\OutputFiles"```
### Specify a full output file path
```powershell -ExecutionPolicy Bypass -File locate_by_extension.ps1 -extension jpg -outputPath "D:\Reports\image_list.txt"```

## 2. locate_by_date.ps1
Usage options for  ```locate_by_date.ps1``` script.
### Specify all options
```powershell -ExecutionPolicy Bypass -File locate_by_date.ps1 -Path "C:\" -Extension ".txt" -DaysBack 30 -MinSize 1000 -OutputFolder "C:\User\YOURNAME\Desktop\locator_logs"```

### Find files modified in the last year (default behavior):
```powershell .\FindFiles.ps1 -Path "C:\Users" -Extension ".txt"```

### Find files older than 2 years:
```powershell .\FindFiles.ps1 -Path "C:\Users" -Extension ".txt" -DaysBackNewest 730 -DaysBackOldest [int]::MaxValue```

### Find files modified between 1 and 2 years ago:
```powershell .\FindFiles.ps1 -Path "C:\Users" -Extension ".txt" -DaysBackNewest 365 -DaysBackOldest 730```

### Find all files, regardless of age:
```powershell .\FindFiles.ps1 -Path "C:\Users" -Extension ".txt" -DaysBackNewest 0 -DaysBackOldest [int]::MaxValue```

## 3. locate_by_substring.ps1 and locate_by_subsubstring_order_by_date.ps1

### Basic Usage
```powershell locate_by_substring.ps1 -substring "report"```

This command will search for all files containing "report" in their names in the current directory and its subdirectories. The results will be saved in a file named "YYYYMMDD_filelist_by_report.txt" in the current directory.

### Specifying Output Directory

```powershell locate_by_substring.ps1 -substring "data" -outputPath "C:\SearchResults"```

This command searches for files with "data" in their names and saves the results in the C:\SearchResults directory. The output file will be named "YYYYMMDD_filelist_by_data.txt".

### Custom Output File Name

```powershell locate_by_substring.ps1 -substring "log" -outputPath "C:\Logs\application_logs.txt"```

This example searches for files containing "log" in their names and saves the results to a specific file named "application_logs.txt" in the C:\Logs directory.

### Searching for File Extensions
```powershell locate_by_substring.ps1 -substring ".docx"```

This command will find all Word documents (files ending with .docx) in the current directory and subdirectories.

### Combining Search Terms
```powershell .\SearchFiles.ps1 -substring "2023_financial"```

This example searches for files that contain both "2023" and "financial" in their names, which could be useful for finding specific yearly reports.
Using with Pipeline

```powershell Get-Content file_list.txt | ForEach-Object { .\SearchFiles.ps1 -substring $_ -outputPath "C:\Results" }```

This advanced example reads substrings from a file and performs a search for each, saving the results in separate files in the C:\Results directory.
