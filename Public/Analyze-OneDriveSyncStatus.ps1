function Analyze-OneDriveSyncStatus {
    [CmdletBinding()]
    param (
        [string]$LogFolder,    # Parameter for the log folder path
        [string]$StatusFileName  # Parameter for the status file name
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
    $Status = Get-Content -Path $statusFile | ConvertFrom-Json

    # Check the status properties
    $Success = @( "Shared", "UpToDate", "Up To Date" )
    $InProgress = @( "SharedSync", "Shared Sync", "Syncing" )
    $Failed = @( "Error", "ReadOnly", "Read Only", "OnDemandOrUnknown", "On Demand or Unknown", "Paused")

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
        }
        else {
            Write-EnhancedLog -Message "Unable to get OneDrive Sync Status for Display Name: $DisplayName, User: $User" -Level "WARNING"
        }
    }
}

# # Example usage with splatting
# $AnalyzeParams = @{
#     LogFolder = "C:\ProgramData\AADMigration\logs"
#     StatusFileName = "OneDriveSyncStatus.json"
# }

# Analyze-OneDriveSyncStatus @AnalyzeParams