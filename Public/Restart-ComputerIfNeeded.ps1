function Restart-ComputerIfNeeded {
    <#
    .SYNOPSIS
    Restarts the computer if necessary.

    .DESCRIPTION
    This function forces a restart of the computer and logs the process. It is typically used after significant system changes that require a reboot.

    .EXAMPLE
    Restart-ComputerIfNeeded

    Forces a computer restart and logs the process.

    .NOTES
    This function should be used with caution as it forces an immediate restart.
    #>

    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting Restart-ComputerIfNeeded function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Restarting computer..." -Level "INFO"
            Restart-Computer -Force
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during the restart process: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Restart-ComputerIfNeeded function" -Level "NOTICE"
        }
    }

    End {
        Write-EnhancedLog -Message "Restart-ComputerIfNeeded function completed" -Level "INFO"
    }
}
