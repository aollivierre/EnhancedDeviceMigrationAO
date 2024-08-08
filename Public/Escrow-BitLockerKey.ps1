function Test-Bitlocker {
    <#
    .SYNOPSIS
    Tests if BitLocker is enabled on the specified drive.

    .DESCRIPTION
    The Test-Bitlocker function tests if BitLocker is enabled on the specified drive.

    .PARAMETER BitlockerDrive
    The drive letter of the BitLocker protected drive.

    .EXAMPLE
    Test-Bitlocker -BitlockerDrive "C:"
    Tests if BitLocker is enabled on drive C:.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$BitlockerDrive
    )

    Begin {
        Write-EnhancedLog -Message "Starting Test-Bitlocker function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            $bitlockerVolume = Get-BitLockerVolume -MountPoint $BitlockerDrive -ErrorAction Stop
            Write-EnhancedLog -Message "BitLocker is enabled on drive: $BitlockerDrive" -Level "INFO"
            return $bitlockerVolume
        }
        catch {
            Write-EnhancedLog -Message "BitLocker is not enabled on drive: $BitlockerDrive. Terminating script!" -Level "ERROR"
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Test-Bitlocker function" -Level "Notice"
    }
}

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