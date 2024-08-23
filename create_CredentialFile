if ($null -eq $CredentialFile -or -not (Test-Path $CredentialFile)) {
    # Handle the case where $CredentialFile is null or the file doesn't exist
    $emailCredential = Get-Credential -Message "Enter the email account credentials"
    $CredentialFile = "$env:USERPROFILE\EmailCredential.xml"
    $emailCredential | Export-Clixml -Path $CredentialFile
    Write-Host "Credential file created at $CredentialFile"
}
