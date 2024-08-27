function Escrow-BitLockerKey {
    <#
    .SYNOPSIS
    Escrows the BitLocker recovery key to Azure AD.

    .DESCRIPTION
    The Escrow-BitLockerKey function tests if BitLocker is enabled on the specified drive, retrieves the key protector ID, and escrows the BitLocker recovery key to Azure AD.

    .PARAMETER DriveLetter
    The drive letter of the BitLocker protected drive.

    .EXAMPLE
    $params = @{
        DriveLetter = "C:"
    }
    Escrow-BitLockerKey @params
    Escrows the BitLocker recovery key for drive C: to Azure AD.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DriveLetter
    )

    Begin {
        Write-EnhancedLog -Message "Starting Escrow-BitLockerKey function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            $bitlockerVolume = Test-Bitlocker -BitlockerDrive $DriveLetter
            $keyProtectorId = Get-KeyProtectorId -BitlockerDrive $DriveLetter
            Invoke-BitlockerEscrow -BitlockerDrive $DriveLetter -BitlockerKey $keyProtectorId
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Escrow-BitLockerKey function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Escrow-BitLockerKey function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     DriveLetter = "C:"
# }
# Escrow-BitLockerKey @params