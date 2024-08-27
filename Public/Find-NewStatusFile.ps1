function Find-NewStatusFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFolder,

        [Parameter(Mandatory = $true)]
        [string]$StatusFileName,

        [Parameter(Mandatory = $true)]
        [int]$MaxRetries = 5,

        [Parameter(Mandatory = $true)]
        [int]$RetryInterval = 10
    )

    Begin {
        Write-EnhancedLog -Message "Starting Find-NewStatusFile function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
        $isSystem = Test-RunningAsSystem
        $fileFound = $false
        $statusFile = $null
    }

    Process {
        $retryCount = 0

        while ($retryCount -lt $MaxRetries -and -not $fileFound) {
            if ($isSystem) {
                $userProfiles = Get-ChildItem 'C:\Users' -Directory | Where-Object { $_.Name -notlike "Public" -and $_.Name -notlike "Default*" }
                foreach ($profile in $userProfiles) {
                    $profileLogFolder = Join-Path -Path $profile.FullName -ChildPath $LogFolder
                    $profileStatusFile = Join-Path -Path $profileLogFolder -ChildPath $StatusFileName
                    if (Test-Path -Path $profileStatusFile) {
                        $fileFound = $true
                        $statusFile = Get-Item -Path $profileStatusFile
                        Write-EnhancedLog -Message "Status file found: $($statusFile.FullName)" -Level "INFO"
                        break
                    }
                }
            }
            else {
                $logFolder = Join-Path -Path $env:USERPROFILE -ChildPath $LogFolder
                $statusFile = Join-Path -Path $logFolder -ChildPath $StatusFileName

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
            throw $errorMessage
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Find-NewStatusFile function" -Level "Notice"
        return $statusFile
    }
}