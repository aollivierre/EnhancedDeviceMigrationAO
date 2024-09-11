# Main function to remove Intune management
function Remove-IntuneMgmt {
    [CmdletBinding()]
    param (
        [string]$OMADMPath,
        [string]$EnrollmentBasePath,
        [string]$TrackedBasePath,
        [string]$PolicyManagerBasePath,
        [string]$ProvisioningBasePath,
        [string]$CertCurrentUserPath,
        [string]$CertLocalMachinePath,
        [string]$TaskPathBase,
        [string]$MSDMProviderID,
        [string[]]$RegistryPathsToRemove,
        [string]$UserCertIssuer,
        [string[]]$DeviceCertIssuers
    )

    Begin {
        # Initialize counters and summary table
        $successCount = 0
        $warningCount = 0
        $errorCount = 0
        $summaryTable = [System.Collections.Generic.List[PSCustomObject]]::new()

        Write-EnhancedLog -Message "Starting Remove-IntuneMgmt function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Check Intune enrollment
            $Account = Check-IntuneEnrollment -OMADMPath $OMADMPath -EnrollmentBasePath $EnrollmentBasePath -MSDMProviderID $MSDMProviderID
            if ($null -eq $Account) {
                Write-EnhancedLog -Message "Device is not enrolled in Intune. No further action required." -Level "INFO"
                $warningCount++
                return
            }

            # Perform cleanup tasks
            $summaryTable.Add((Remove-ScheduledTasks -TaskPathBase $TaskPathBase -Account $Account))
            $summaryTable.Add((Remove-RegistryKeys -RegistryPathsToRemove $RegistryPathsToRemove -Account $Account))
            $summaryTable.Add((Remove-UserCertificates -CertCurrentUserPath $CertCurrentUserPath -UserCertIssuer $UserCertIssuer))
            $summaryTable.Add((Remove-DeviceCertificates -CertLocalMachinePath $CertLocalMachinePath -DeviceCertIssuers $DeviceCertIssuers))
            $successCount++
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while removing Intune management: $($_.Exception.Message)" -Level "ERROR"
            $errorCount++
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        # Generate final summary report
        # Define a hashtable for splatting
        $reportParams = @{
            successCount = $successCount
            warningCount = $warningCount
            errorCount   = $errorCount
            summaryTable = $summaryTable
        }

        # Call the function using the splat
        Generate-RemoveIntuneMgmtSummaryReport @reportParams


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
