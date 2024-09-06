function Remove-IntuneMgmt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OMADMPath,

        [Parameter(Mandatory = $true)]
        [string]$EnrollmentBasePath,

        [Parameter(Mandatory = $true)]
        [string]$TrackedBasePath,

        [Parameter(Mandatory = $true)]
        [string]$PolicyManagerBasePath,

        [Parameter(Mandatory = $true)]
        [string]$ProvisioningBasePath,

        [Parameter(Mandatory = $true)]
        [string]$CertCurrentUserPath,

        [Parameter(Mandatory = $true)]
        [string]$CertLocalMachinePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskPathBase,

        [Parameter(Mandatory = $true)]
        [string]$MSDMProviderID,

        [Parameter(Mandatory = $true)]
        [string[]]$RegistryPathsToRemove,

        [Parameter(Mandatory = $true)]
        [string]$UserCertIssuer,

        [Parameter(Mandatory = $true)]
        [string[]]$DeviceCertIssuers
    )

    Begin {
        Write-EnhancedLog -Message "Starting Remove-IntuneMgmt function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Starting the Intune unenrollment process" -Level "NOTICE"
    
            # Check Intune enrollment status
            Write-EnhancedLog -Message "Checking Intune enrollment status from registry path $OMADMPath" -Level "INFO"
            $Account = (Get-ItemProperty -Path $OMADMPath -ErrorAction SilentlyContinue).PSChildName
            if ($null -eq $Account) {
                Write-EnhancedLog -Message "No Intune enrollment account found at path $OMADMPath" -Level "WARNING"
                return
            }
    
            Write-EnhancedLog -Message "Enrollment account detected: $Account" -Level "INFO"
            $Enrolled = $true
            $EnrollmentPath = "$EnrollmentBasePath\$Account"
            
            Write-EnhancedLog -Message "Checking UPN and ProviderID at enrollment path: $EnrollmentPath" -Level "INFO"
            $EnrollmentUPN = (Get-ItemProperty -Path $EnrollmentPath -ErrorAction SilentlyContinue).UPN
            $ProviderID = (Get-ItemProperty -Path $EnrollmentPath -ErrorAction SilentlyContinue).ProviderID
    
            if (-not $EnrollmentUPN) {
                Write-EnhancedLog -Message "Enrollment UPN not found at $EnrollmentPath" -Level "WARNING"
                $Enrolled = $false
            }
    
            if ($ProviderID -ne $MSDMProviderID) {
                Write-EnhancedLog -Message "ProviderID does not match the expected value at $EnrollmentPath" -Level "WARNING"
                $Enrolled = $false
            }
    
            if ($Enrolled) {
                Write-EnhancedLog -Message "Device is enrolled in Intune. Proceeding with unenrollment." -Level "INFO"
    
                # Remove Scheduled Tasks
                Write-EnhancedLog -Message "Attempting to remove scheduled tasks at path $TaskPathBase\$Account" -Level "INFO"
                Get-ScheduledTask -TaskPath "$TaskPathBase\$Account\*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
                Write-EnhancedLog -Message "Scheduled tasks removed successfully (if any existed)" -Level "INFO"
    
                # Remove registry keys
                Write-EnhancedLog -Message "Attempting to remove registry keys associated with enrollment" -Level "INFO"
                foreach ($RegistryPath in $RegistryPathsToRemove) {
                    Write-EnhancedLog -Message "Removing registry path: $RegistryPath\$Account" -Level "INFO"
                    Remove-Item -Path "$RegistryPath\$Account" -Recurse -Force -ErrorAction SilentlyContinue
                }
                Write-EnhancedLog -Message "Registry keys removed successfully (if any existed)" -Level "INFO"
    
                # Remove enrollment certificates from user store
                Write-EnhancedLog -Message "Attempting to remove user certificates with issuer: $UserCertIssuer" -Level "INFO"
                $UserCerts = Get-ChildItem -Path $CertCurrentUserPath -Recurse
                $IntuneCerts = $UserCerts | Where-Object { $_.Issuer -eq $UserCertIssuer }
                foreach ($Cert in $IntuneCerts) {
                    Write-EnhancedLog -Message "Removing certificate: $($Cert.Subject)" -Level "INFO"
                    $Cert | Remove-Item -Force
                }
                Write-EnhancedLog -Message "User certificates removed successfully" -Level "INFO"
    
                # Remove enrollment certificates from local machine store
                Write-EnhancedLog -Message "Attempting to remove device certificates with issuers: $DeviceCertIssuers" -Level "INFO"
                $DeviceCerts = Get-ChildItem -Path $CertLocalMachinePath -Recurse
                $IntuneCerts = $DeviceCerts | Where-Object { $DeviceCertIssuers -contains $_.Issuer }
                foreach ($Cert in $IntuneCerts) {
                    Write-EnhancedLog -Message "Removing device certificate: $($Cert.Subject)" -Level "INFO"
                    $Cert | Remove-Item -Force -ErrorAction SilentlyContinue
                }
                Write-EnhancedLog -Message "Device certificates removed successfully" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Device is not enrolled in Intune. No further action required." -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while removing Intune management: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }
    

    End {
        Write-EnhancedLog -Message "Exiting Remove-IntuneMgmt function" -Level "INFO"
    }
}


# $RemoveIntuneMgmtParams = @{
#     OMADMPath              = "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*"
#     EnrollmentBasePath     = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments"
#     TrackedBasePath        = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked"
#     PolicyManagerBasePath  = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager"
#     ProvisioningBasePath   = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning"
#     CertCurrentUserPath    = "cert:\CurrentUser"
#     CertLocalMachinePath   = "cert:\LocalMachine"
#     TaskPathBase           = "\Microsoft\Windows\EnterpriseMgmt"
#     MSDMProviderID         = "MS DM Server"
#     RegistryPathsToRemove  = @(
#         "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments",
#         "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\Status",
#         "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked",
#         "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled",
#         "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\Providers",
#         "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts",
#         "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Logger",
#         "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions"
#     )
#     UserCertIssuer         = "CN=SC_Online_Issuing"
#     DeviceCertIssuers      = @("CN=Microsoft Intune Root Certification Authority", "CN=Microsoft Intune MDM Device CA")
# }

# Remove-IntuneMgmt @RemoveIntuneMgmtParams
