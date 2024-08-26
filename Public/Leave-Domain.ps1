
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