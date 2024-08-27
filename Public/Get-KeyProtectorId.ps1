function Get-KeyProtectorId {
    <#
    .SYNOPSIS
    Retrieves the key protector ID for the specified drive.

    .DESCRIPTION
    The Get-KeyProtectorId function retrieves the key protector ID for the specified BitLocker protected drive.

    .PARAMETER BitlockerDrive
    The drive letter of the BitLocker protected drive.

    .EXAMPLE
    Get-KeyProtectorId -BitlockerDrive "C:"
    Retrieves the key protector ID for drive C:.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$BitlockerDrive
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-KeyProtectorId function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            $bitlockerVolume = Get-BitLockerVolume -MountPoint $BitlockerDrive
            $keyProtector = $bitlockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
            Write-EnhancedLog -Message "Retrieved key protector ID for drive: $BitlockerDrive" -Level "INFO"
            return $keyProtector.KeyProtectorId
        }
        catch {
            Write-EnhancedLog -Message "Failed to retrieve key protector ID for drive: $BitlockerDrive" -Level "ERROR"
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-KeyProtectorId function" -Level "Notice"
    }
}