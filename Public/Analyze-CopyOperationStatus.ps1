function Analyze-CopyOperationStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the log folder path.")]
        [string]$LogFolder,

        [Parameter(Mandatory = $true, HelpMessage = "Provide the status file name.")]
        [string]$StatusFileName
    )

    # Define the status file path
    $statusFile = Join-Path -Path $LogFolder -ChildPath $StatusFileName

    # Retry mechanism parameters
    $maxRetries = 5
    $retryInterval = 5
    $retryCount = 0
    $fileFound = $false

    # Retry loop to check if the status file exists
    while ($retryCount -lt $maxRetries -and -not $fileFound) {
        if (Test-Path -Path $statusFile) {
            $fileFound = $true
            Write-EnhancedLog -Message "Status file found: $statusFile" -Level "INFO"
        } else {
            Write-EnhancedLog -Message "Status file not found: $statusFile. Retrying in $retryInterval seconds..." -Level "WARNING"
            Start-Sleep -Seconds $retryInterval
            $retryCount++
        }
    }

    # If the file is still not found after retries, exit
    if (-not $fileFound) {
        Write-EnhancedLog -Message "Status file not found after $maxRetries retries: $statusFile" -Level "ERROR"
        return
    }

    # Read the status file
    $statusData = Get-Content -Path $statusFile | ConvertFrom-Json

    # Analyze the status of each operation
    foreach ($entry in $statusData) {
        $sourcePath = $entry.SourcePath
        $backupFolderName = $entry.BackupFolderName
        $backupStatus = $entry.BackupStatus
        $timestamp = $entry.Timestamp

        if ($backupStatus -eq "Success") {
            Write-EnhancedLog -Message "Backup operation succeeded: Source: $sourcePath, Backup Folder: $backupFolderName, Timestamp: $timestamp" -Level "INFO"
        }
        elseif ($backupStatus -eq "Failed") {
            Write-EnhancedLog -Message "Backup operation failed: Source: $sourcePath, Backup Folder: $backupFolderName, Timestamp: $timestamp" -Level "ERROR"
            if ($entry.VerificationResults) {
                foreach ($result in $entry.VerificationResults) {
                    Write-EnhancedLog -Message "Discrepancy: Status: $($result.Status), Source Path: $($result.SourcePath), Expected/Actual Path: $($result.ExpectedPath -or $result.ActualPath)" -Level "WARNING"
                }
            }
        }
        else {
            Write-EnhancedLog -Message "Unknown backup status for Source: $sourcePath, Backup Folder: $backupFolderName, Timestamp: $timestamp" -Level "WARNING"
        }
    }
}

# # Example usage with splatting
# $AnalyzeParams = @{
#     LogFolder = "C:\ProgramData\BackupLogs"
#     StatusFileName = "UserFilesBackupStatus.json"
# }

# Analyze-CopyOperationStatus @AnalyzeParams
