function Check-DomainMembership {
    <#
    .SYNOPSIS
    Checks if the computer is part of a domain.

    .DESCRIPTION
    This function checks the current domain membership status of the computer by querying the Win32_ComputerSystem class.

    .EXAMPLE
    $isDomainJoined = Check-DomainMembership

    This will check if the computer is part of a domain and return a Boolean value.

    .NOTES
    This function returns a Boolean indicating whether the computer is part of a domain or not.
    #>

    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting Check-DomainMembership function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Querying Win32_ComputerSystem to check domain membership status" -Level "INFO"

            # Query the computer system's domain membership status
            $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
            $PartOfDomain = $ComputerSystem.PartOfDomain

            if ($PartOfDomain) {
                Write-EnhancedLog -Message "Device is part of a domain." -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Device is not part of a domain." -Level "WARNING"
            }

            return $PartOfDomain
        }
        catch {
            Write-EnhancedLog -Message "Error occurred while checking domain membership: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            # Log exit and cleanup
            Write-EnhancedLog -Message "Exiting Check-DomainMembership function" -Level "NOTICE"
        }
    }

    End {
        Write-EnhancedLog -Message "Check-DomainMembership function completed" -Level "INFO"
    }
}
