
function Invoke-BitlockerEscrow {
    <#
    .SYNOPSIS
    Escrows the BitLocker recovery key to Azure AD.

    .DESCRIPTION
    The Invoke-BitlockerEscrow function escrows the BitLocker recovery key for the specified drive to Azure AD.

    .PARAMETER BitlockerDrive
    The drive letter of the BitLocker protected drive.

    .PARAMETER BitlockerKey
    The key protector ID to be escrowed.

    .EXAMPLE
    Invoke-BitlockerEscrow -BitlockerDrive "C:" -BitlockerKey "12345678-1234-1234-1234-123456789012"
    Escrows the BitLocker recovery key for drive C: to Azure AD.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$BitlockerDrive,

        [Parameter(Mandatory = $true)]
        [string]$BitlockerKey
    )

    Begin {
        Write-EnhancedLog -Message "Starting Invoke-BitlockerEscrow function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Escrowing the BitLocker recovery key to Azure AD for drive: $BitlockerDrive" -Level "INFO"
            BackupToAAD-BitLockerKeyProtector -MountPoint $BitlockerDrive -KeyProtectorId $BitlockerKey -ErrorAction SilentlyContinue
            Write-EnhancedLog -Message "Attempted to escrow key in Azure AD - Please verify manually!" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while escrowing the BitLocker key to Azure AD" -Level "ERROR"
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Invoke-BitlockerEscrow function" -Level "Notice"
    }
}