function Remove-ExistingStatusFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFolder,

        [Parameter(Mandatory = $true)]
        [string]$StatusFileName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Remove-ExistingStatusFiles function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
        $statusFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        $isSystem = Test-RunningAsSystem
    }

    Process {
        if ($isSystem) {
            Write-EnhancedLog -Message "Running as SYSTEM. Analyzing logs across all user profiles." -Level "INFO"
            $userProfiles = Get-ChildItem 'C:\Users' -Directory | Where-Object { $_.Name -notlike "Public" -and $_.Name -notlike "Default*" }

            foreach ($profile in $userProfiles) {
                $profileLogFolder = Join-Path -Path $profile.FullName -ChildPath $LogFolder
                $profileStatusFile = Join-Path -Path $profileLogFolder -ChildPath $StatusFileName
                if (Test-Path -Path $profileStatusFile) {
                    $statusFiles.Add((Get-Item -Path $profileStatusFile))
                }
            }

            if ($statusFiles.Count -gt 0) {
                foreach ($file in $statusFiles) {
                    if (Test-Path -Path $file.FullName) {
                        $removeParams = @{
                            Path               = $file.FullName
                            ForceKillProcesses = $true
                            MaxRetries         = 5
                            RetryInterval      = 10
                        }
                        Remove-EnhancedItem @removeParams
                        Write-EnhancedLog -Message "Removed existing status file: $($file.FullName)" -Level "INFO"
                    }
                }
            }
            else {
                Write-EnhancedLog -Message "No status files found across user profiles." -Level "WARNING"
            }
        }
        else {
            #Not Running as SYSTEM but running As User so we will scan the current user profile instead of all user profiles
            $logFolder = Join-Path -Path $env:USERPROFILE -ChildPath $LogFolder
            $statusFile = Join-Path -Path $logFolder -ChildPath $StatusFileName

            if (Test-Path -Path $statusFile) {
                $removeParams = @{
                    Path               = $statusFile
                    ForceKillProcesses = $true
                    MaxRetries         = 5
                    RetryInterval      = 10
                }
                Remove-EnhancedItem @removeParams
                Write-EnhancedLog -Message "Removed existing status file: $statusFile" -Level "INFO"
            }
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Remove-ExistingStatusFiles function" -Level "Notice"
    }
}