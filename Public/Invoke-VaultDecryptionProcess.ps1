function Invoke-VaultDecryptionProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter your GitHub Personal Access Token (PAT) as a SecureString.")]
        [SecureString] $SecurePAT,
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the GitHub repository owner.")]
        [string] $RepoOwner = "aollivierre",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the GitHub repository name.")]
        [string] $RepoName = "Vault",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the release tag version.")]
        [string] $ReleaseTag = "0.1",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the file name to download from the release.")]
        [string] $FileName = "vault.GH.Asset.zip",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the destination path for the downloaded file.")]
        [string] $DestinationPath = "C:\temp\vault.GH.Asset.zip",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the path to the ZIP file to be decrypted.")]
        [string] $ZipFilePath = "C:\temp\vault.zip",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the path to the Base64-encoded certificate file.")]
        [string] $CertBase64Path = "C:\temp\vault\certs\cert.pfx.base64",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the path to the certificate password text file.")]
        [string] $CertPasswordPath = "C:\temp\vault\certs\certpassword.txt",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the path to the encrypted AES key in Base64 format.")]
        [string] $KeyBase64Path = "C:\temp\vault\certs\secret.key.encrypted.base64",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the path to the encrypted file that needs to be decrypted.")]
        [string] $EncryptedFilePath = "C:\temp\vault\vault.zip.encrypted",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the directory for storing certificate and key-related temporary files.")]
        [string] $CertsDir = "C:\temp\vault\certs",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the path to store the decrypted file.")]
        [string] $DecryptedFilePath = "C:\temp\vault.zip",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the KeePass database file path.")]
        [string] $KeePassDatabasePath = "C:\temp\vault-decrypted\myDatabase.kdbx",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the KeePass key file path.")]
        [string] $KeyFilePath = "C:\temp\vault-decrypted\myKeyFile.keyx",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the KeePass entry name.")]
        [string] $EntryName = "ICTC-EJ-PPKG",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the attachment name in KeePass to be exported.")]
        [string] $AttachmentName = "ICTC_Project_2_Aug_29_2024.zip",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the export path for the KeePass attachment.")]
        [string] $ExportPath = "C:\temp\vault-decrypted\ICTC_Project_2_Aug_29_2024-fromdb.zip",
    
        [Parameter(Mandatory = $true, HelpMessage = "Specify the destination directory where the final decrypted and exported files will be placed.")]
        [string] $FinalDestinationDirectory = "C:\temp\vault-decrypted"
    )

    Begin {
        # Log the parameters
        Write-EnhancedLog -Message "Starting Invoke-VaultDecryptionProcess" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Convert SecureString to plain text
        try {
            $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePAT)
            $pat = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        }
        catch {
            Handle-Error -Message "Failed to convert SecureString to plain text." -ErrorRecord $_
        }
    }

    Process {
        try {
            # Step 1: Download the GitHub Release Asset
            $downloadParams = @{
                Token           = $pat
                RepoOwner       = $RepoOwner
                RepoName        = $RepoName
                ReleaseTag      = $ReleaseTag
                FileName        = $FileName
                DestinationPath = $DestinationPath
            }
            Write-EnhancedLog -Message "Downloading GitHub Release Asset..." -Level 'INFO'
            Download-GitHubReleaseAsset @downloadParams

            # Step 2: Unzip the downloaded file
            $unzipParams = @{
                ZipFilePath          = $DestinationPath
                DestinationDirectory = "C:\temp\vault"
            }
            Write-EnhancedLog -Message "Unzipping the downloaded asset..." -Level 'INFO'
            Unzip-Directory @unzipParams

            # Step 3: Decrypt the file using the certificate and AES
            $decryptParams = @{
                CertBase64Path    = $CertBase64Path
                CertPasswordPath  = $CertPasswordPath
                KeyBase64Path     = $KeyBase64Path
                EncryptedFilePath = $EncryptedFilePath
                DecryptedFilePath = $DecryptedFilePath
                CertsDir          = $CertsDir
            }
            Write-EnhancedLog -Message "Decrypting the file using AES + RSA (Cert)..." -Level 'INFO'
            Decrypt-FileWithCert @decryptParams

            # Step 4: Unzip the decrypted file
            $unzipDecryptedParams = @{
                ZipFilePath          = $ZipFilePath
                DestinationDirectory = $FinalDestinationDirectory
            }
            Write-EnhancedLog -Message "Unzipping the decrypted file..." -Level 'INFO'
            Unzip-Directory @unzipDecryptedParams

            # Step 5: Export the attachment from KeePass
            $exportAttachmentParams = @{
                DatabasePath   = $KeePassDatabasePath
                KeyFilePath    = $KeyFilePath
                EntryName      = $EntryName
                AttachmentName = $AttachmentName
                ExportPath     = $ExportPath
            }
            Write-EnhancedLog -Message "Exporting attachment from KeePass database..." -Level 'INFO'
            Export-KeePassAttachment @exportAttachmentParams

            # Step 6: Unzip the final exported attachment
            $unzipFinalParams = @{
                ZipFilePath          = $ExportPath
                DestinationDirectory = $FinalDestinationDirectory
            }
            Write-EnhancedLog -Message "Unzipping the final exported attachment..." -Level 'INFO'
            Unzip-Directory @unzipFinalParams

            Write-EnhancedLog -Message "Process completed successfully!" -Level 'INFO'
        }
        catch {
            Handle-Error -Message "An error occurred during the process." -ErrorRecord $_
        }
    }

    End {
        # Clean up secure data
        try {
            $pat = $null
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
        catch {
            Handle-Error -Message "Failed to clean up secure data." -ErrorRecord $_
        }

        Write-EnhancedLog -Message "Exiting Invoke-VaultDecryptionProcess" -Level "Notice"
    }
}
