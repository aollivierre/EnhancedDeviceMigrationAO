function Perform-KFMSync {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OneDriveExePath,

        [Parameter(Mandatory = $true)]
        [string]$ScheduledTaskName,

        [Parameter(Mandatory = $true)]
        [string]$ScheduledTaskDescription
    )

    Begin {
        Write-EnhancedLog -Message "Starting Perform-KFMSync function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Performing KFM sync" -Level "INFO"
            $ODProcess = Get-Process -Name OneDrive -ErrorAction SilentlyContinue

            if ($ODProcess) {
                $ODProcess | Stop-Process -Confirm:$false -Force
                Start-Sleep -Seconds 5

                Unregister-ScheduledTaskWithLogging -TaskName $ScheduledTaskName

                $CreateOneDriveRemediationTaskParams = @{
                    OneDriveExePath           = $OneDriveExePath
                    ScheduledTaskName         = $ScheduledTaskName
                    ScheduledTaskDescription  = $ScheduledTaskDescription
                }
                
                Create-OneDriveRemediationTask @CreateOneDriveRemediationTaskParams
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while performing KFM sync: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Perform-KFMSync function" -Level "Notice"
    }
}
