function Check-DomainMembership {
    <#
    .SYNOPSIS
        Checks if the computer is part of a domain.
    
    .DESCRIPTION
        This function checks the current domain membership status of the computer by querying the Win32_ComputerSystem class.
    
    .EXAMPLE
        $isDomainJoined = Check-DomainMembership
    
    .NOTES
        This function returns a Boolean indicating whether the computer is part of a domain.
    #>
    [CmdletBinding()]
    param ()
    
    Begin {
        Write-EnhancedLog -Message "Starting Check-DomainMembership function" -Level "NOTICE"
    }
    
    Process {
        Write-EnhancedLog -Message "Checking if device is domain joined" -Level "INFO"
        $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $PartOfDomain = $ComputerSystem.PartOfDomain
        return $PartOfDomain
    }
    
    End {
        Write-EnhancedLog -Message "Exiting Check-DomainMembership function" -Level "NOTICE"
    }
}

function Leave-Domain {
    <#
        .SYNOPSIS
            Removes the computer from the domain.
        
        .DESCRIPTION
            This function attempts to remove the computer from the domain using provided credentials. If domain credentials fail, it falls back to using local credentials.
        
        .PARAMETER DomainLeaveUser
            The domain user account to use for leaving the domain.
        
        .PARAMETER DomainLeavePassword
            The password for the domain user account.
        
        .PARAMETER ComputerName
            The name of the computer to remove from the domain.
        
        .PARAMETER TempUser
            The temporary local user to use if domain credentials fail.
        
        .PARAMETER TempUserPassword
            The password for the temporary local user.
        
        .EXAMPLE
            Leave-Domain -DomainLeaveUser "AdminUser" -DomainLeavePassword "P@ssw0rd" -ComputerName "localhost" -TempUser "LocalAdmin" -TempUserPassword "P@ssw0rd"
        
        .NOTES
            This function removes the computer from the domain, using domain credentials if possible.
        #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DomainLeaveUser,
        
        [Parameter(Mandatory = $false)]
        [string]$DomainLeavePassword,
        
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [string]$TempUser,
        
        [Parameter(Mandatory = $true)]
        [string]$TempUserPassword
    )
        
    Begin {
        Write-EnhancedLog -Message "Starting Leave-Domain function" -Level "NOTICE"
    }
        
    Process {
        if ($DomainLeaveUser) {
            $SecurePassword = ConvertTo-SecureString -String $DomainLeavePassword -AsPlainText -Force
            $Credentials = New-Object System.Management.Automation.PSCredential($DomainLeaveUser, $SecurePassword)
        
            try {
                Remove-Computer -ComputerName $ComputerName -Credential $Credentials -Verbose -Force -ErrorAction Stop
            }
            catch {
                Write-EnhancedLog -Message "Leaving domain with domain credentials failed. Will leave domain with local account." -Level "ERROR"
                # Fallback to local user
                $SecurePassword = ConvertTo-SecureString -String $TempUserPassword -AsPlainText -Force
                $Credentials = New-Object System.Management.Automation.PSCredential($TempUser, $SecurePassword)
                Remove-Computer -ComputerName $ComputerName -Credential $Credentials -Verbose -Force
            }
        }
    }
        
    End {
        Write-EnhancedLog -Message "Exiting Leave-Domain function" -Level "NOTICE"
    }
}
function Disable-ScheduledTaskByPath {
    <#
            .SYNOPSIS
                Disables a scheduled task by its name and path.
            
            .DESCRIPTION
                This function disables a scheduled task specified by its task name and path.
            
            .PARAMETER TaskName
                The name of the scheduled task.
            
            .PARAMETER TaskPath
                The path of the scheduled task.
            
            .EXAMPLE
                Disable-ScheduledTaskByPath -TaskName "TaskName" -TaskPath "\Folder\"
            
            .NOTES
                This function is useful for disabling tasks located in specific subfolders within the Task Scheduler.
            #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
            
        [Parameter(Mandatory = $true)]
        [string]$TaskPath
    )
            
    Begin {
        Write-EnhancedLog -Message "Starting Disable-ScheduledTaskByPath function" -Level "NOTICE"
    }
            
    Process {
        $Task = Get-ScheduledTask | Where-Object { $_.TaskPath -eq $TaskPath -and $_.TaskName -eq $TaskName }
                    
        if ($Task) {
            Disable-ScheduledTask -TaskName ($Task.TaskPath + $Task.TaskName)
            Write-Host "Scheduled task '$($Task.TaskPath + $Task.TaskName)' has been disabled."
        }
        else {
            Write-Host "Scheduled task '$TaskPath$TaskName' not found."
        }
    }
            
    End {
        Write-EnhancedLog -Message "Exiting Disable-ScheduledTaskByPath function" -Level "NOTICE"
    }
}

function Manage-NetworkAdapters {
    <#
                .SYNOPSIS
                    Manages the state of network adapters.
                
                .DESCRIPTION
                    This function disables or enables all connected network adapters based on the provided parameter.
                
                .PARAMETER Disable
                    Switch parameter to disable network adapters. If not provided, the function will enable the adapters.
                
                .EXAMPLE
                    Manage-NetworkAdapters -Disable
                
                .EXAMPLE
                    Manage-NetworkAdapters
                
                .NOTES
                    This function is useful for temporarily disabling network connectivity during specific operations.
                #>
    [CmdletBinding()]
    param (
        [switch]$Disable
    )
                
    Begin {
        Write-EnhancedLog -Message "Starting Manage-NetworkAdapters function" -Level "NOTICE"
    }
                
    Process {
        $ConnectedAdapters = Get-NetAdapter | Where-Object { $_.MediaConnectionState -eq "Connected" }
                
        foreach ($Adapter in $ConnectedAdapters) {
            if ($Disable) {
                Write-EnhancedLog -Message "Disabling network adapter $($Adapter.Name)" -Level "INFO"
                Disable-NetAdapter -Name $Adapter.Name -Confirm:$false
            }
            else {
                Write-EnhancedLog -Message "Enabling network adapter $($Adapter.Name)" -Level "INFO"
                Enable-NetAdapter -Name $Adapter.Name -Confirm:$false
            }
        }
    }
                
    End {
        Write-EnhancedLog -Message "Exiting Manage-NetworkAdapters function" -Level "NOTICE"
    }
}
function Restart-ComputerIfNeeded {
    <#
    .SYNOPSIS
        Restarts the computer.
    
    .DESCRIPTION
        This function forces a restart of the computer.
    
    .EXAMPLE
        Restart-ComputerIfNeeded
    
    .NOTES
        This function is typically used after making significant changes to the system that require a restart.
    #>
    [CmdletBinding()]
    param ()
    
    Begin {
        Write-EnhancedLog -Message "Starting Restart-ComputerIfNeeded function" -Level "NOTICE"
    }
    
    Process {
        Write-EnhancedLog -Message "Restarting computer..." -Level "INFO"
        Restart-Computer -Force
    }
    
    End {
        Write-EnhancedLog -Message "Exiting Restart-ComputerIfNeeded function" -Level "NOTICE"
    }
}
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