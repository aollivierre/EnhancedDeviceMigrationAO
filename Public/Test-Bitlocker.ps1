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
