function Enable-LocalUserAccounts {
    <#
    .SYNOPSIS
    Enables all local user accounts.
  
    .DESCRIPTION
    The Enable-LocalUserAccounts function enables all local user accounts, without any filtering.
  
    .EXAMPLE
    Enable-LocalUserAccounts
    Enables all local user accounts.
    #>
  
    [CmdletBinding()]
    param ()
  
    Begin {
        Write-EnhancedLog -Message "Starting Enable-LocalUserAccounts function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }
  
    Process {
        try {
            # Get all local user accounts
            $users = Get-LocalUser
            
            foreach ($user in $users) {
                Write-EnhancedLog -Message "Enabling local user account: $($user.Name)" -Level "INFO"
                Enable-LocalUser -Name $user.Name -ErrorAction Stop
                Write-EnhancedLog -Message "Successfully enabled local user account: $($user.Name)" -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Enable-LocalUserAccounts function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }
  
    End {
        Write-EnhancedLog -Message "Exiting Enable-LocalUserAccounts function" -Level "Notice"
    }
}

# Example usage
# Enable-LocalUserAccounts
