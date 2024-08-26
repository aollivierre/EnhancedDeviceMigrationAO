function Analyze-OneDriveSyncStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFolder,    # Parameter for the log folder path

        [Parameter(Mandatory = $true)]
        [string]$StatusFileName  # Parameter for the status file name
    )

    Begin {
        Write-EnhancedLog -Message "Starting Analyze-OneDriveSyncStatus function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Define the status file path
        $statusFile = Join-Path -Path $LogFolder -ChildPath $StatusFileName

        # Remove the existing status file if found
        if (Test-Path -Path $statusFile) {
            Remove-Item -Path $statusFile -Force
            Write-EnhancedLog -Message "Removed existing status file: $statusFile" -Level "INFO"
        }
    }

    Process {
        try {
            # Retry mechanism parameters
            $maxRetries = 5
            $retryInterval = 5
            $retryCount = 0
            $fileFound = $false

            Write-EnhancedLog -Message "Starting retry mechanism to check for status file." -Level "INFO"

            # Retry loop to check if the status file exists
            while ($retryCount -lt $maxRetries -and -not $fileFound) {
                if (Test-Path -Path $statusFile) {
                    $fileFound = $true
                    Write-EnhancedLog -Message "Status file found: $statusFile" -Level "INFO"
                } else {
                    Write-EnhancedLog -Message "Status file not found: $statusFile. Retrying in $retryInterval seconds... (Attempt $($retryCount + 1) of $maxRetries)" -Level "WARNING"
                    Start-Sleep -Seconds $retryInterval
                    $retryCount++
                }
            }

            # If the file is still not found after retries, exit
            if (-not $fileFound) {
                Write-EnhancedLog -Message "Status file not found after $maxRetries retries: $statusFile" -Level "ERROR"
                return
            }

            Write-EnhancedLog -Message "Reading status file: $statusFile" -Level "INFO"

            # Read the status file
            $Status = Get-Content -Path $statusFile | ConvertFrom-Json

            Write-EnhancedLog -Message "Analyzing OneDrive sync status" -Level "INFO"

            # Define status categories
            $Success = @( "Shared", "UpToDate", "Up To Date" )
            $InProgress = @( "SharedSync", "Shared Sync", "Syncing" )
            $Failed = @( "Error", "ReadOnly", "Read Only", "OnDemandOrUnknown", "On Demand or Unknown", "Paused")

            # Check the status properties
            ForEach ($s in $Status) {
                $StatusString = $s.StatusString
                $DisplayName = $s.DisplayName
                $User = $s.UserName

                if ($StatusString -in $Success) {
                    Write-EnhancedLog -Message "OneDrive sync status is healthy: Display Name: $DisplayName, User: $User, Status: $StatusString" -Level "INFO"
                }
                elseif ($StatusString -in $InProgress) {
                    Write-EnhancedLog -Message "OneDrive sync status is currently syncing: Display Name: $DisplayName, User: $User, Status: $StatusString" -Level "WARNING"
                }
                elseif ($StatusString -in $Failed) {
                    Write-EnhancedLog -Message "OneDrive sync status is in a known error state: Display Name: $DisplayName, User: $User, Status: $StatusString" -Level "ERROR"
                    Write-EnhancedLog -Message "Exiting due to OneDrive sync error state." -Level "CRITICAL"
                    exit 1
                }
                else {
                    Write-EnhancedLog -Message "Unable to get OneDrive Sync Status for Display Name: $DisplayName, User: $User" -Level "WARNING"
                }
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during the OneDrive sync status analysis: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_  # Re-throw the error after logging it
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Analyze-OneDriveSyncStatus function" -Level "Notice"
    }
}


# # Example usage with splatting
# $AnalyzeParams = @{
#     LogFolder = "C:\ProgramData\AADMigration\logs"
#     StatusFileName = "OneDriveSyncStatus.json"
# }

# Analyze-OneDriveSyncStatus @AnalyzeParams