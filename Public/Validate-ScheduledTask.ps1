function Validate-ScheduledTask {
    <#
    .SYNOPSIS
    Validates whether a scheduled task exists and meets the expected criteria.

    .DESCRIPTION
    The Validate-ScheduledTask function checks if a scheduled task exists at the specified task path and validates its properties.

    .PARAMETER TaskPath
    The path of the task in Task Scheduler.

    .PARAMETER TaskName
    The name of the scheduled task.

    .EXAMPLE
    Validate-ScheduledTask -TaskPath "AAD Migration" -TaskName "Run Post-migration cleanup"
    Validates if the scheduled task exists and meets the expected criteria.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Validate-ScheduledTask function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            $taskExists = Get-ScheduledTask -TaskPath "\$TaskPath\" -TaskName $TaskName -ErrorAction SilentlyContinue
            if ($taskExists) {
                Write-EnhancedLog -Message "Scheduled task '$TaskName' exists at '$TaskPath'." -Level "INFO"
                return $true
            } else {
                Write-EnhancedLog -Message "Scheduled task '$TaskName' does not exist at '$TaskPath'." -Level "WARNING"
                return $false
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Validate-ScheduledTask function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Validate-ScheduledTask function" -Level "Notice"
    }
}