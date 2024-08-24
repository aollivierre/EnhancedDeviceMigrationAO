function Main-MigrateToAADJOnly {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PPKGName,
        
        [Parameter(Mandatory = $false)]
        [string]$DomainLeaveUser,
        
        [Parameter(Mandatory = $false)]
        [string]$DomainLeavePassword,
        
        [Parameter(Mandatory = $true)]
        [string]$TempUser,
        
        [Parameter(Mandatory = $true)]
        [string]$TempUserPassword,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Main-MigrateToAADJOnly function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Test provisioning package
            $TestProvisioningPackParams = @{
                PPKGName = $PPKGName
            }
            Test-ProvisioningPack @TestProvisioningPackParams

            # Add local user
            $AddLocalUserParams = @{
                TempUser         = $TempUser
                TempUserPassword = $TempUserPassword
                Description      = "account for autologin"
                Group            = "Administrators"
            }
            Add-LocalUser @AddLocalUserParams

            # Set autologin
            $SetAutologinParams = @{
                TempUser            = $TempUser
                TempUserPassword    = $TempUserPassword
                RegPath             = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
                AutoAdminLogonName  = 'AutoAdminLogon'
                AutoAdminLogonValue = '1'
                DefaultUsernameName = 'DefaultUsername'
                DefaultPasswordName = 'DefaultPassword'
            }
            Set-Autologin @SetAutologinParams

            # Disable OOBE privacy
            $DisableOOBEPrivacyParams = @{
                OOBERegistryPath      = 'HKLM:\Software\Policies\Microsoft\Windows\OOBE'
                OOBEName              = 'DisablePrivacyExperience'
                OOBEValue             = '1'
                AnimationRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
                AnimationName         = 'EnableFirstLogonAnimation'
                AnimationValue        = '0'
                LockRegistryPath      = 'HKLM:\Software\Policies\Microsoft\Windows\Personalization'
                LockName              = 'NoLockScreen'
                LockValue             = '1'
            }
            Disable-OOBEPrivacy @DisableOOBEPrivacyParams

            # Set RunOnce script
            $SetRunOnceParams = @{
                ScriptPath      = $ScriptPath
                RunOnceKey      = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
                PowershellPath  = "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe"
                ExecutionPolicy = "Unrestricted"
                RunOnceName     = "NextRun"
            }
            Set-RunOnce @SetRunOnceParams

            # Suspend BitLocker with reboot count
            $SuspendBitLockerWithRebootParams = @{
                MountPoint  = "C:"
                RebootCount = 3
            }
            Suspend-BitLockerWithReboot @SuspendBitLockerWithRebootParams

            # Remove Intune management
            $RemoveIntuneMgmtParams = @{
                OMADMPath             = "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*"
                EnrollmentBasePath    = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments"
                TrackedBasePath       = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked"
                PolicyManagerBasePath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager"
                ProvisioningBasePath  = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning"
                CertCurrentUserPath   = "cert:\CurrentUser"
                CertLocalMachinePath  = "cert:\LocalMachine"
                TaskPathBase          = "\Microsoft\Windows\EnterpriseMgmt"
                MSDMProviderID        = "MS DM Server"
                RegistryPathsToRemove = @(
                    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments",
                    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\Status",
                    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked",
                    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled",
                    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\Providers",
                    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts",
                    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Logger",
                    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions"
                )
                UserCertIssuer        = "CN=SC_Online_Issuing"
                DeviceCertIssuers     = @("CN=Microsoft Intune Root Certification Authority", "CN=Microsoft Intune MDM Device CA")
            }
            Remove-IntuneMgmt @RemoveIntuneMgmtParams

            # Remove hybrid join
            Remove-Hybrid

            # Remove AD join
            $RemoveADJoinParams = @{
                TempUser         = $TempUser
                TempUserPassword = $TempUserPassword
                ComputerName     = "localhost"
                TaskName         = "PR4B-AADM Launch PSADT for Interactive Migration"
                TaskPath         = "\AAD Migration\"
            }
            Remove-ADJoin @RemoveADJoinParams

        }
        catch {
            Write-EnhancedLog -Message "An error occurred: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Main-MigrateToAADJOnly function" -Level "Notice"
    }
}


# $MainMigrateParams = @{
#     PPKGName            = "YourProvisioningPackName"
#     DomainLeaveUser     = "YourDomainUser"
#     DomainLeavePassword = "YourDomainPassword"
#     TempUser            = "YourTempUser"
#     TempUserPassword    = "YourTempUserPassword"
#     ScriptPath          = "C:\ProgramData\AADMigration\Scripts\PostRunOnce.ps1"
# }

# Main-MigrateToAADJOnly @MainMigrateParams
