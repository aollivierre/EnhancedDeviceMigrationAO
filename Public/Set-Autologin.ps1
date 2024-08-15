function Set-Autologin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TempUser,

        [Parameter(Mandatory = $true)]
        [string]$TempUserPassword,

        [Parameter(Mandatory = $true)]
        [string]$RegPath ,

        [Parameter(Mandatory = $true)]
        [string]$AutoAdminLogonName ,

        [Parameter(Mandatory = $true)]
        [string]$AutoAdminLogonValue ,

        [Parameter(Mandatory = $true)]
        [string]$DefaultUsernameName,

        [Parameter(Mandatory = $true)]
        [string]$DefaultPasswordName ,

        [Parameter(Mandatory = $false)]
        [string]$DefaultDomainName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Set-Autologin function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Setting user account $TempUser to Auto Login" -Level "INFO"

            $autoLoginParams = @{
                Path  = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
                Name  = "AutoAdminLogon"
                Value = "1"
            }

            if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\AutoAdminLogon") {
                Remove-ItemProperty @autoLoginParams
            }

            # Set AutoAdminLogon
            Set-ItemProperty -Path $RegPath -Name $AutoAdminLogonName -Value $AutoAdminLogonValue -Type String -Verbose

            # Set DefaultUserName
            Set-ItemProperty -Path $RegPath -Name $DefaultUsernameName -Value $TempUser -Type String -Verbose

            # Set DefaultPassword
            Set-ItemProperty -Path $RegPath -Name $DefaultPasswordName -Value $TempUserPassword -Type String -Verbose

            # Set DefaultDomainName if provided
            if ($PSBoundParameters.ContainsKey('DefaultDomainName')) {
                Set-ItemProperty -Path $RegPath -Name 'DefaultDomainName' -Value $DefaultDomainName -Type String -Verbose
            }

            # Create UserList key if it doesn't exist and add the user
            $userListPath = "$RegPath\SpecialAccounts\UserList"
            if (-not (Test-Path -Path $userListPath)) {
                Write-EnhancedLog -Message "Creating UserList registry path: $userListPath" -Level "INFO"
                New-Item -Path $userListPath -Force
            }
            New-ItemProperty -Path $userListPath -Name $TempUser -Value 0 -PropertyType DWord -Force -Verbose

            Write-EnhancedLog -Message "Auto-login set for user '$TempUser'." -Level 'INFO'
        } catch {
            Write-EnhancedLog -Message "An error occurred while setting autologin: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Set-Autologin function" -Level "INFO"
    }
}

# # Example usage with splatting
# $SetAutologinParams = @{
#     TempUser            = 'YourTempUser'
#     TempUserPassword    = 'YourTempUserPassword'
#     RegPath             = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
#     AutoAdminLogonName  = 'AutoAdminLogon'
#     AutoAdminLogonValue = '1'
#     DefaultUsernameName = 'DefaultUserName'
#     DefaultPasswordName = 'DefaultPassword'
#     DefaultDomainName   = $env:COMPUTERNAME
# }

# Set-Autologin @SetAutologinParams
