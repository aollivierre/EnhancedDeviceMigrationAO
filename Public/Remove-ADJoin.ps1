function Remove-ADJoin {
    <#
    .SYNOPSIS
        Removes the computer from the Active Directory domain.
    
    .DESCRIPTION
        This function checks if the computer is part of an Active Directory domain and, if so, removes it from the domain.
        It also disables specified scheduled tasks, manages network adapters, and restarts the computer if necessary.
    
    .PARAMETER DomainLeaveUser
        The domain user account to use for leaving the domain.
    
    .PARAMETER DomainLeavePassword
        The password for the domain user account.
    
    .PARAMETER TempUser
        The temporary local user to use if domain credentials fail.
    
    .PARAMETER TempUserPassword
        The password for the temporary local user.
    
    .PARAMETER ComputerName
        The name of the computer to remove from the domain.
    
    .PARAMETER TaskName
        The name of the scheduled task to be disabled.
    
    .PARAMETER TaskPath
        The path of the scheduled task to be disabled.
    
    .EXAMPLE
        Remove-ADJoin -DomainLeaveUser "AdminUser" -DomainLeavePassword "P@ssw0rd" -TempUser "LocalAdmin" -TempUserPassword "P@ssw0rd" -ComputerName "localhost" -TaskName "TaskName" -TaskPath "\Path\To\Task"
    
    .NOTES
        This function performs multiple actions, including removing the computer from the domain, disabling scheduled tasks, managing network adapters, and restarting the computer.
    #>
    [CmdletBinding()]
    param (
        [string]$DomainLeaveUser,
        [string]$DomainLeavePassword,
        [string]$TempUser,
        [string]$TempUserPassword,
        [string]$ComputerName,
        [string]$TaskName,
        [string]$TaskPath
    )
    
    Begin {
        Write-EnhancedLog -Message "Starting Remove-ADJoin function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }
    
    Process {
        try {
            $PartOfDomain = Check-DomainMembership
    
            if ($PartOfDomain) {
                Write-EnhancedLog -Message "Computer is domain member, removing domain membership" -Level "INFO"
                $leaveDomainParams = @{
                    DomainLeaveUser     = $DomainLeaveUser
                    DomainLeavePassword = $DomainLeavePassword
                    ComputerName        = $ComputerName
                    TempUser            = $TempUser
                    TempUserPassword    = $TempUserPassword
                }
                
                Leave-Domain @leaveDomainParams
                
    
                Disable-ScheduledTaskByPath -TaskName $TaskName -TaskPath $TaskPath
    
                Manage-NetworkAdapters -Disable
                Start-Sleep -Seconds 5
                Manage-NetworkAdapters
    
                # Restart-ComputerIfNeeded
            }
            else {
                Write-EnhancedLog -Message "Computer is not a domain member, no domain removal needed." -Level "INFO"
                Disable-ScheduledTaskByPath -TaskName $TaskName -TaskPath $TaskPath
                # Restart-ComputerIfNeeded
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while removing AD join: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }
    
    End {
        Write-EnhancedLog -Message "Exiting Remove-ADJoin function" -Level "NOTICE"
    }
}