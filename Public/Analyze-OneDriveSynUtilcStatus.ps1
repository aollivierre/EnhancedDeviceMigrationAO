function Analyze-OneDriveSyncUtilStatus {
    <#
    .SYNOPSIS
    Analyzes the OneDrive sync status from a JSON file.

    .DESCRIPTION
    The Analyze-OneDriveSyncUtilStatus function reads the OneDrive sync status from a specified JSON file, and categorizes the status as healthy, in progress, or failed based on predefined conditions.

    .PARAMETER LogFolder
    The path to the folder where the log files are stored.

    .PARAMETER StatusFileName
    The name of the JSON file containing the OneDrive sync status.

    .EXAMPLE
    $params = @{
        LogFolder     = "C:\ProgramData\AADMigration\logs"
        StatusFileName = "OneDriveSyncStatus.json"
    }
    Analyze-OneDriveSyncUtilStatus @params
    Analyzes the OneDrive sync status from the specified JSON file.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFolder,

        [Parameter(Mandatory = $true)]
        [string]$StatusFileName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Analyze-OneDriveSyncUtilStatus function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Define the status file path
        $statusFile = Join-Path -Path $LogFolder -ChildPath $StatusFileName
    }

    Process {
        try {
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
                $errorMessage = "Status file not found after $maxRetries retries: $statusFile"
                Write-EnhancedLog -Message $errorMessage -Level "ERROR"
                throw $errorMessage
            }

            # Read the status file
            $Status = Get-Content -Path $statusFile | ConvertFrom-Json

            # Define the status categories
            $Success = @("Synced", "UpToDate", "Up To Date")
            $InProgress = @("Syncing", "SharedSync", "Shared Sync")
            $Failed = @("Error", "ReadOnly", "Read Only", "OnDemandOrUnknown", "On Demand or Unknown", "Paused")

            # Analyze the status
            $StatusString = $Status.CurrentStateString
            $UserName = $Status.UserName

            if ($StatusString -in $Success) {
                Write-EnhancedLog -Message "OneDrive sync status is healthy: User: $UserName, Status: $StatusString" -Level "INFO"
            }
            elseif ($StatusString -in $InProgress) {
                Write-EnhancedLog -Message "OneDrive sync status is currently syncing: User: $UserName, Status: $StatusString" -Level "WARNING"
            }
            elseif ($StatusString -in $Failed) {
                Write-EnhancedLog -Message "OneDrive sync status is in a known error state: User: $UserName, Status: $StatusString" -Level "ERROR"
            }
            else {
                Write-EnhancedLog -Message "Unable to determine OneDrive Sync Status for User: $UserName" -Level "WARNING"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Analyze-OneDriveSyncUtilStatus function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Analyze-OneDriveSyncUtilStatus function" -Level "Notice"
    }
}

# # # Example usage
# $params = @{
#     LogFolder     = "C:\ProgramData\AADMigration\logs"
#     StatusFileName = "ODSyncUtilStatus.json"
# }
# Analyze-OneDriveSyncUtilStatus @params
