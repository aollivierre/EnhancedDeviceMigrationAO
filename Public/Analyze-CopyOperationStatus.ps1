function Analyze-CopyOperationStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the log folder path.")]
        [string]$LogFolder,

        [Parameter(Mandatory = $true, HelpMessage = "Provide the status file name.")]
        [string]$StatusFileName,

        [Parameter(Mandatory = $true)]
        [int]$MaxRetries = 5,

        [Parameter(Mandatory = $true)]
        [int]$RetryInterval = 10
    )

    Begin {
        Write-EnhancedLog -Message "Starting Analyze-CopyOperationStatus function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # # Step 1: Remove existing status files
            # Remove-ExistingStatusFiles -LogFolder $LogFolder -StatusFileName $StatusFileName

            # Step 2: Find the new status file
            $statusFile = Find-NewStatusFile -LogFolder $LogFolder -StatusFileName $StatusFileName -MaxRetries $MaxRetries -RetryInterval $RetryInterval

            # Step 3: Analyze the status file
            Write-EnhancedLog -Message "Reading status file: $($statusFile.FullName)" -Level "INFO"
            $statusData = Get-Content -Path $statusFile.FullName | ConvertFrom-Json

            # Analyze the status of each operation
            Write-EnhancedLog -Message "Analyzing copy operation status from the JSON data" -Level "INFO"
            foreach ($entry in $statusData) {
                $sourcePath = $entry.SourcePath
                $backupFolderName = $entry.BackupFolderName
                $backupStatus = $entry.BackupStatus
                $timestamp = $entry.Timestamp

                if ($backupStatus -eq "Success") {
                    Write-EnhancedLog -Message "Copy operation succeeded: Source: $sourcePath, Backup Folder: $backupFolderName, Timestamp: $timestamp" -Level "INFO"
                }
                elseif ($backupStatus -eq "Failed") {
                    Write-EnhancedLog -Message "Copy operation failed: Source: $sourcePath, Backup Folder: $backupFolderName, Timestamp: $timestamp" -Level "ERROR"
                    if ($entry.VerificationResults) {
                        foreach ($result in $entry.VerificationResults) {
                            Write-EnhancedLog -Message "Discrepancy: Status: $($result.Status), Source Path: $($result.SourcePath), Expected/Actual Path: $($result.ExpectedPath -or $result.ActualPath)" -Level "WARNING"
                        }
                    }
                }
                else {
                    Write-EnhancedLog -Message "Unknown copy operation status for Source: $sourcePath, Backup Folder: $backupFolderName, Timestamp: $timestamp" -Level "WARNING"
                }
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Analyze-CopyOperationStatus function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Analyze-CopyOperationStatus function" -Level "Notice"
    }
}
