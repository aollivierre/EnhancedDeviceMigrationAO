function Trigger-ScheduledTask {
    [CmdletBinding()]
    param (
        [string]$TaskPath,
        [string]$TaskName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Trigger-ScheduledTask function" -Level "NOTICE"
        CheckAndElevate -ElevateIfNotAdmin $true
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Validate if the scheduled task exists before triggering
            $isTaskValid = Validate-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
            if (-not $isTaskValid) {
                Write-EnhancedLog -Message "Validation failed. The scheduled task '$TaskName' does not exist or is invalid." -Level "ERROR"
                return
            }

            # Proceed with triggering the task if validation passed
            Write-EnhancedLog -Message "Triggering the scheduled task '$TaskName' under the '$TaskPath' folder..." -Level "INFO"

            $startTaskParams = @{
                TaskPath = $TaskPath
                TaskName = $TaskName
            }

            Start-ScheduledTask @startTaskParams

            Write-EnhancedLog -Message "Scheduled task triggered successfully." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while triggering the scheduled task: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Trigger-ScheduledTask function" -Level "NOTICE"
    }
}
