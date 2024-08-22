# locator
scripts for locating different files: 

1. locate_by_extension.ps1
   
   **Useage:** ```
# Use default output location (current directory)
powershell -ExecutionPolicy Bypass -File list_files.ps1 -extension pdf

# Specify only an output directory
powershell -ExecutionPolicy Bypass -File list_files.ps1 -extension docx -outputPath "C:\OutputFiles"

# Specify a full output file path
powershell -ExecutionPolicy Bypass -File list_files.ps1 -extension jpg -outputPath "D:\Reports\image_list.txt"```
   
3. locate_by_date.ps1

   **Useage:** ```.\locate_by_date.ps1 -Path "C:\Users" -Extension ".txt" -DaysBack 30 -MinSize 1000 -OutputFolder "C:\Reports"```
