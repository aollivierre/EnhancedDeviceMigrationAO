function Disable-LocalUserAccounts {
    <#
    .SYNOPSIS
    Disables all enabled local user accounts except for default accounts and optionally skips specific accounts in Dev mode.
  
    .DESCRIPTION
    The Disable-LocalUserAccounts function disables all enabled local user accounts except for default accounts. In Dev mode, specific accounts can be skipped, such as 'admin-abdullah'.
  
    .PARAMETER Mode
    Specifies the mode in which the script should run. Options are "Dev" for development mode or "Prod" for production mode. In Dev mode, the 'admin-abdullah' account is skipped.
  
    .EXAMPLE
    Disable-LocalUserAccounts -Mode Dev
    Disables all enabled local user accounts except for default accounts and skips 'admin-abdullah' in Dev mode.
  
    .EXAMPLE
    Disable-LocalUserAccounts -Mode Prod
    Disables all enabled local user accounts including 'admin-abdullah' in Prod mode.
    #>
  
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Dev", "Prod")]
        [string]$Mode = "Prod"
    )
  
    Begin {
        Write-EnhancedLog -Message "Starting Disable-LocalUserAccounts function in $Mode mode" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }
  
    Process {
        try {
            # Get all enabled local user accounts except for default accounts
            $users = Get-LocalUser | Where-Object { $_.Enabled -eq $true -and $_.Name -notlike 'default*' }
            
            foreach ($user in $users) {
                if ($Mode -eq "Dev" -and $user.Name -eq "admin-abdullah") {
                    Write-EnhancedLog -Message "Skipping disabling of account 'admin-abdullah' in Dev mode" -Level "WARNING"
                    continue
                }

                Write-EnhancedLog -Message "Disabling local user account: $($user.Name)" -Level "INFO"
                Disable-LocalUser -Name $user.Name -ErrorAction Stop
                Write-EnhancedLog -Message "Successfully disabled local user account: $($user.Name)" -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Disable-LocalUserAccounts function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }
  
    End {
        Write-EnhancedLog -Message "Exiting Disable-LocalUserAccounts function" -Level "Notice"
    }
}

# Example usage
# Disable-LocalUserAccounts -Mode Dev
# Disable-LocalUserAccounts -Mode Prod
