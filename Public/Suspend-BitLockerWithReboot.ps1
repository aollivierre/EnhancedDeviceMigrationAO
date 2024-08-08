function Suspend-BitLockerWithReboot {
    <#
    .SYNOPSIS
    Suspends BitLocker and configures the system to reboot a specified number of times.

    .DESCRIPTION
    The Suspend-BitLockerWithReboot function suspends BitLocker protection on the specified drive and configures the system to reboot a specified number of times.

    .PARAMETER MountPoint
    The drive letter of the BitLocker protected drive.

    .PARAMETER RebootCount
    The number of reboots to suspend BitLocker protection for.

    .EXAMPLE
    $params = @{
        MountPoint  = "C:"
        RebootCount = 2
    }
    Suspend-BitLockerWithReboot @params
    Suspends BitLocker on drive C: for 2 reboots.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MountPoint,

        [Parameter(Mandatory = $true)]
        [int]$RebootCount
    )

    Begin {
        Write-EnhancedLog -Message "Starting Suspend-BitLockerWithReboot function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Suspending BitLocker on drive $MountPoint for $RebootCount reboots" -Level "INFO"
            Suspend-BitLocker -MountPoint $MountPoint -RebootCount $RebootCount -Verbose
            Write-EnhancedLog -Message "Successfully suspended BitLocker on drive $MountPoint" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while suspending BitLocker: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Suspend-BitLockerWithReboot function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     MountPoint  = "C:"
#     RebootCount = 2
# }
# Suspend-BitLockerWithReboot @params
