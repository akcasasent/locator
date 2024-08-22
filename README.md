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
```powershell -ExecutionPolicy Bypass -File locate_by_date.ps1 -Path "C:\" -Extension ".txt" -DaysBack 30 -MinSize 1000 -OutputFolder "C:\User\YOURNAME\Desktop\locator_logs"```
