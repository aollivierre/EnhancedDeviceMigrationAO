function Remove-LocalUserAccount {
    <#
    .SYNOPSIS
    Removes a local user account.
  
    .DESCRIPTION
    The Remove-LocalUserAccount function removes a specified local user account.
  
    .PARAMETER UserName
    The name of the local user account to be removed.
  
    .EXAMPLE
    $params = @{
        UserName = "TempUser"
    }
    Remove-LocalUserAccount @params
    Removes the local user account named TempUser.
    #>
  
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
  
    Begin {
        Write-EnhancedLog -Message "Starting Remove-LocalUserAccount function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }
  
    Process {
        try {
            Write-EnhancedLog -Message "Removing local user account: $UserName" -Level "INFO"
            Remove-LocalUser -Name $UserName -ErrorAction Stop
            Write-EnhancedLog -Message "Successfully removed local user account: $UserName" -Level "INFO"
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
  #   UserName = "TempUser"
  # }
  # Remove-LocalUserAccount @params