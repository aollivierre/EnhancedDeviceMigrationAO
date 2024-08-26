function Check-DomainMembership {
    <#
    .SYNOPSIS
        Checks if the computer is part of a domain.
    
    .DESCRIPTION
        This function checks the current domain membership status of the computer by querying the Win32_ComputerSystem class.
    
    .EXAMPLE
        $isDomainJoined = Check-DomainMembership
    
    .NOTES
        This function returns a Boolean indicating whether the computer is part of a domain.
    #>
    [CmdletBinding()]
    param ()
    
    Begin {
        Write-EnhancedLog -Message "Starting Check-DomainMembership function" -Level "NOTICE"
    }
    
    Process {
        Write-EnhancedLog -Message "Checking if device is domain joined" -Level "INFO"
        $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $PartOfDomain = $ComputerSystem.PartOfDomain
        return $PartOfDomain
    }
    
    End {
        Write-EnhancedLog -Message "Exiting Check-DomainMembership function" -Level "NOTICE"
    }
}
