function Disable-LocalUserAccounts {
    <#
    .SYNOPSIS
    Disables all enabled local user accounts except for default accounts.
  
    .DESCRIPTION
    The Disable-LocalUserAccounts function disables all enabled local user accounts except for default accounts.
  
    .EXAMPLE
    Disable-LocalUserAccounts
    Disables all enabled local user accounts except for default accounts.
    #>
  
    [CmdletBinding()]
    param ()
  
    Begin {
        Write-EnhancedLog -Message "Starting Disable-LocalUserAccounts function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }
  
    Process {
        try {
            # Get all enabled local user accounts except for default accounts
            $users = Get-LocalUser | Where-Object { $_.Enabled -eq $true -and $_.Name -notlike 'default*' }
            
            foreach ($user in $users) {
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
# Disable-LocalUserAccounts
