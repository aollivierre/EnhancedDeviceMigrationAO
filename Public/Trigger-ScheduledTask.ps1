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

# # Example usage
# # Define parameters using a hashtable
# $taskParams = @{
#     TaskPath = "\AAD Migration"
#     TaskName = "AADM Get OneDrive Sync Status"
# }

# # Call the function with splatting
# Trigger-ScheduledTask @taskParams