function Check-OneDriveSyncStatus {
    [CmdletBinding()]
    param (
        [string]$OneDriveLibPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Check-OneDriveSyncStatus function" -Level "NOTICE"
        Log-Params -Params @{ OneDriveLibPath = $OneDriveLibPath }

        # Ensure the script is not running with elevated privileges
        CheckAndElevate

        # Import OneDriveLib.dll to check current OneDrive Sync Status
        try {
            if (-not (Test-Path $OneDriveLibPath)) {
                Write-EnhancedLog -Message "The specified OneDriveLib.dll path does not exist: $OneDriveLibPath" -Level "ERROR"
                throw "The specified OneDriveLib.dll path does not exist."
            }

            Import-Module $OneDriveLibPath
            Write-EnhancedLog -Message "Successfully imported OneDriveLib module from $OneDriveLibPath" -Level "INFO"
        } catch {
            Write-EnhancedLog -Message "Failed to import OneDriveLib module: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    Process {
        try {
            $Status = Get-ODStatus

            if (-not $Status) {
                Write-EnhancedLog -Message "OneDrive is not running or the user is not logged in to OneDrive." -Level "WARNING"
                return
            }

            # Create objects with known statuses listed.
            $Success = @( "Shared", "UpToDate", "Up To Date" )
            $InProgress = @( "SharedSync", "Shared Sync", "Syncing" )
            $Failed = @( "Error", "ReadOnly", "Read Only", "OnDemandOrUnknown", "On Demand or Unknown", "Paused")

            # Iterate through all accounts to check status and log the result.
            ForEach ($s in $Status) {
                $StatusString = $s.StatusString
                $DisplayName = $s.DisplayName
                $User = $s.UserName

                if ($StatusString -in $Success) {
                    Write-EnhancedLog -Message "OneDrive sync status is healthy: Display Name: $DisplayName, User: $User, Status: $StatusString" -Level "INFO"
                }
                elseif ($StatusString -in $InProgress) {
                    Write-EnhancedLog -Message "OneDrive sync status is currently syncing: Display Name: $DisplayName, User: $User, Status: $StatusString" -Level "INFO"
                }
                elseif ($StatusString -in $Failed) {
                    Write-EnhancedLog -Message "OneDrive sync status is in a known error state: Display Name: $DisplayName, User: $User, Status: $StatusString" -Level "ERROR"
                }
                else {
                    Write-EnhancedLog -Message "Unable to get OneDrive Sync Status for Display Name: $DisplayName, User: $User" -Level "WARNING"
                }
            }
        } catch {
            Write-EnhancedLog -Message "An error occurred while checking OneDrive sync status: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Check-OneDriveSyncStatus function" -Level "NOTICE"
    }
}



# # Example usage
# $params = @{
#     OneDriveLibPath = "C:\ProgramData\AADMigration\Files\OneDriveLib.dll"
# }
# Check-OneDriveSyncStatus @params