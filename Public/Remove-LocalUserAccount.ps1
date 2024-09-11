function Remove-LocalUserAccount {
    <#
    .SYNOPSIS
    Removes a specified local user account.

    .DESCRIPTION
    The Remove-LocalUserAccount function removes a specified local user account if it exists.

    .PARAMETER UserName
    The name of the local user account to be removed.

    .EXAMPLE
    $params = @{
        UserName = "MigrationInProgress"
    }
    Remove-LocalUserAccount @params
    Removes the local user account named "MigrationInProgress".
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Remove-LocalUserAccount function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Check if running in PowerShell 7 or later and import LocalAccounts
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            Write-EnhancedLog -Message "Running in PowerShell 7. Importing LocalAccounts module using Windows PowerShell..." -Level "INFO"
            try {
                Import-Module -Name Microsoft.PowerShell.LocalAccounts -UseWindowsPowerShell -ErrorAction Stop
            }
            catch {
                Write-EnhancedLog -Message "Failed to import LocalAccounts module: $($_.Exception.Message)" -Level "ERROR"
                throw
            }
        }
    }

    Process {
        try {
            # Check if the user account exists
            $user = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue

            if ($null -eq $user) {
                Write-EnhancedLog -Message "User account '$UserName' does not exist. No action taken." -Level "WARNING"
            }
            else {
                if ($PSCmdlet.ShouldProcess("User Account", "Removing user account '$UserName'")) {
                    Write-EnhancedLog -Message "Removing local user account: $UserName" -Level "INFO"
                    Remove-LocalUser -Name $UserName -ErrorAction Stop
                    Write-EnhancedLog -Message "Successfully removed local user account: $UserName" -Level "INFO"
                }
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Remove-LocalUserAccount function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Remove-LocalUserAccount function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     UserName = "MigrationInProgress"
# }
# Remove-LocalUserAccount @params