function Restart-ComputerIfNeeded {
    <#
    .SYNOPSIS
        Restarts the computer.
    
    .DESCRIPTION
        This function forces a restart of the computer.
    
    .EXAMPLE
        Restart-ComputerIfNeeded
    
    .NOTES
        This function is typically used after making significant changes to the system that require a restart.
    #>
    [CmdletBinding()]
    param ()
    
    Begin {
        Write-EnhancedLog -Message "Starting Restart-ComputerIfNeeded function" -Level "NOTICE"
    }
    
    Process {
        Write-EnhancedLog -Message "Restarting computer..." -Level "INFO"
        Restart-Computer -Force
    }
    
    End {
        Write-EnhancedLog -Message "Exiting Restart-ComputerIfNeeded function" -Level "NOTICE"
    }
}