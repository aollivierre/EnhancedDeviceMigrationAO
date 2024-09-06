function Find-NewStatusFile {
    <#
    .SYNOPSIS
    Finds the status file in user profiles or system context with retries.

    .DESCRIPTION
    This function searches for a specified status file in user profiles or system context (depending on whether the script is running as SYSTEM).
    It will retry the search up to a defined number of times with a specified interval between retries if the file is not found on the first attempt.

    .PARAMETER LogFolder
    The folder name within the user profile or system context where the log file is expected to be found.

    .PARAMETER StatusFileName
    The name of the status file to be located.

    .PARAMETER MaxRetries
    The maximum number of retry attempts to find the status file.

    .PARAMETER RetryInterval
    The time (in seconds) to wait between retry attempts.

    .EXAMPLE
    Find-NewStatusFile -LogFolder "logs" -StatusFileName "ODSyncUtilStatus.json" -MaxRetries 5 -RetryInterval 10

    This command will search for the status file "ODSyncUtilStatus.json" in the "logs" folder, retrying up to 5 times with a 10-second interval between retries.

    .NOTES
    Author: Abdullah Ollivierre
    Date: 2024-09-06

    .LINK
    https://github.com/yourproject/documentation

    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = "Specify the log folder path.")]
        [string]$LogFolder,

        [Parameter(Mandatory = $true,
            HelpMessage = "Specify the status file name.")]
        [string]$StatusFileName,

        [Parameter(Mandatory = $true,
            HelpMessage = "Specify the maximum number of retries.")]
        [ValidateRange(1, 100)]
        [int]$MaxRetries,

        [Parameter(Mandatory = $true,
            HelpMessage = "Specify the interval (in seconds) between retries.")]
        [ValidateRange(1, 60)]
        [int]$RetryInterval
    )

    Begin {
        Write-EnhancedLog -Message "Starting Find-NewStatusFile function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
        $isSystem = Test-RunningAsSystem
        $fileFound = $false
        $statusFile = $null
    }

    Process {
        $retryCount = 0

        try {
            while ($retryCount -lt $MaxRetries -and -not $fileFound) {
                Write-EnhancedLog -Message "Attempt $($retryCount + 1) of $MaxRetries to find status file" -Level "INFO"

                if ($isSystem) {
                    $userProfiles = Get-ChildItem 'C:\Users' -Directory | Where-Object { $_.Name -notlike "Public" -and $_.Name -notlike "Default*" }
                    foreach ($profile in $userProfiles) {
                        $profileLogFolder = Join-Path -Path $profile.FullName -ChildPath $LogFolder
                        $profileStatusFile = Join-Path -Path $profileLogFolder -ChildPath $StatusFileName
                        Write-EnhancedLog -Message "Checking status file in profile: $($profile.FullName)" -Level "INFO"
                        if (Test-Path -Path $profileStatusFile) {
                            $fileFound = $true
                            $statusFile = Get-Item -Path $profileStatusFile
                            Write-EnhancedLog -Message "Status file found in $($statusFile.FullName)" -Level "INFO"
                            break
                        }
                    }
                }
                else {
                    $logFolder = Join-Path -Path $env:USERPROFILE -ChildPath $LogFolder
                    $statusFile = Join-Path -Path $logFolder -ChildPath $StatusFileName
                    Write-EnhancedLog -Message "Checking status file in current user's profile: $logFolder" -Level "INFO"

                    if (Test-Path -Path $statusFile) {
                        $fileFound = $true
                        Write-EnhancedLog -Message "Status file found: $statusFile" -Level "INFO"
                    }
                }

                if (-not $fileFound) {
                    Write-EnhancedLog -Message "Status file not found. Retrying in $RetryInterval seconds..." -Level "WARNING"
                    Start-Sleep -Seconds $RetryInterval
                    $retryCount++
                }
            }

            if (-not $fileFound) {
                $errorMessage = "Status file not found after $MaxRetries retries."
                Write-EnhancedLog -Message $errorMessage -Level "ERROR"
                Write-EnhancedLog -Message "Please check if you are logged in to OneDrive and try again." -Level "ERROR"
                throw [System.Exception]::new($errorMessage)
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Find-NewStatusFile: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_  # Rethrow the error to halt the script if necessary
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Find-NewStatusFile function" -Level "NOTICE"
        return $statusFile
    }
}
