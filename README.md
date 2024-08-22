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
