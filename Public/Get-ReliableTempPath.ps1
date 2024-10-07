function Get-ReliableTempPath {
    <#
    .SYNOPSIS
    Retrieves a reliable temporary directory path using multiple fallback methods with logging.

    .DESCRIPTION
    The Get-ReliableTempPath function attempts to retrieve the system's temporary directory path using the most reliable methods first (e.g., .NET method) and falls back to other methods like environment variables if necessary. It logs each step and returns the path or throws an error if no valid path can be found.

    .PARAMETER LogLevel
    The logging level for messages (e.g., INFO, NOTICE, WARNING, ERROR).

    .EXAMPLE
    $params = @{
        LogLevel = "INFO"
    }
    $tempPath = Get-ReliableTempPath @params
    Retrieves the temporary directory path and logs the process.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the log level for logging.")]
        [string]$LogLevel = "INFO"
    )

    Begin {
        Write-AADMigrationLog -Message "Starting Get-ReliableTempPath function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Initialize tempPath as null
        $tempPath = $null
    }

    Process {
        try {
            Write-AADMigrationLog -Message "Attempting to get temp path using .NET method [System.IO.Path]::GetTempPath()" -Level $LogLevel

            # Attempt to get temp path using [System.IO.Path]::GetTempPath()
            $tempPath = [System.IO.Path]::GetTempPath()

            # Validate if path exists
            if ($tempPath -and (Test-Path -Path $tempPath)) {
                Write-AADMigrationLog -Message "Using .NET method [System.IO.Path]::GetTempPath() - Temp path: $tempPath" -Level $LogLevel
            }
            else {
                Write-AADMigrationLog -Message "Warning: [System.IO.Path]::GetTempPath() returned null or invalid path." -Level "WARNING"
                $tempPath = $null
            }
        }
        catch {
            Write-AADMigrationLog -Message "Error: Exception when using [System.IO.Path]::GetTempPath(): $_" -Level "ERROR"
            $tempPath = $null
        }

        if (-not $tempPath) {
            Write-AADMigrationLog -Message "Falling back to environment variable \$env:TEMP" -Level $LogLevel

            # Fallback to $env:TEMP if .NET method fails
            if ($env:TEMP -and (Test-Path -Path $env:TEMP)) {
                $tempPath = $env:TEMP
                Write-AADMigrationLog -Message "Using environment variable \$env:TEMP - Temp path: $tempPath" -Level $LogLevel
            }
            else {
                Write-AADMigrationLog -Message "Warning: \$env:TEMP is either null or invalid." -Level "WARNING"
                $tempPath = $null
            }
        }

        if (-not $tempPath) {
            Write-AADMigrationLog -Message "Falling back to environment variable \$env:TMP" -Level $LogLevel

            # Fallback to $env:TMP if $env:TEMP fails
            if ($env:TMP -and (Test-Path -Path $env:TMP)) {
                $tempPath = $env:TMP
                Write-AADMigrationLog -Message "Using environment variable \$env:TMP - Temp path: $tempPath" -Level $LogLevel
            }
            else {
                Write-AADMigrationLog -Message "Warning: \$env:TMP is either null or invalid." -Level "WARNING"
                $tempPath = $null
            }
        }

        if (-not $tempPath) {
            Write-AADMigrationLog -Message "Falling back to \$env:USERPROFILE\Temp" -Level $LogLevel

            # Fallback to $env:USERPROFILE\Temp if all else fails
            if ($env:USERPROFILE -and (Test-Path -Path "$env:USERPROFILE\Temp")) {
                $tempPath = "$env:USERPROFILE\Temp"
                Write-AADMigrationLog -Message "Using fallback \$env:USERPROFILE\Temp - Temp path: $tempPath" -Level $LogLevel
            }
            else {
                Write-AADMigrationLog -Message "Error: Could not determine a valid temp path. All methods failed." -Level "ERROR"
                throw "Could not determine a valid temp path."
            }
        }
    }

    End {
        # Log the final temp path
        Write-AADMigrationLog -Message "Final temp path: $tempPath" -Level $LogLevel
        Write-AADMigrationLog -Message "Exiting Get-ReliableTempPath function" -Level "Notice"


        # Ensure $tempPath doesn't have an extra slash
        $tempPath = $tempPath.TrimEnd('\')

        # Return the temp path
        return $tempPath
    }
}

# # Example usage
# try {
#     $params = @{
#         LogLevel = "INFO"
#     }
#     $tempPath = Get-ReliableTempPath @params
#     Write-Host "Temp Path Set To: $tempPath"
# }
# catch {
#     Write-Host "Failed to get a valid temp path: $_"
# }


# # Example usage
# try {
#     $tempPath = Get-ReliableTempPath -LogLevel "INFO"
#     Write-Host "Temp Path Set To: $tempPath"
# }
# catch {
#     Write-Host "Failed to get a valid temp path: $_"
# }
