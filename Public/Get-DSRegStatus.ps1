
function Get-DSRegStatus {
    <#
    .SYNOPSIS
    Checks the device's join status (Workgroup, Azure AD Joined, Hybrid Joined, or On-prem Joined) and MDM enrollment (Intune Enrolled or Not).

    .DESCRIPTION
    The Get-DSRegStatus function runs the dsregcmd /status command and parses its output to determine the device's join status and whether it is enrolled in Microsoft Intune.

    .NOTES
    Version:        1.3
    Author:         Abdullah Ollivierre
    Creation Date:  2024-08-15
    #>

    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting Get-DSRegStatus function" -Level "Notice"
    }

    Process {
        try {
            # Execute dsregcmd /status
            Write-EnhancedLog -Message "Running dsregcmd /status" -Level "INFO"
            $dsregcmdOutput = dsregcmd /status

            # Parse dsregcmd output to determine join status
            Write-EnhancedLog -Message "Parsing dsregcmd output" -Level "INFO"

            $isAzureADJoined = $dsregcmdOutput -match '.*AzureAdJoined\s*:\s*YES'
            $isHybridJoined = $dsregcmdOutput -match '.*DomainJoined\s*:\s*YES' -and $isAzureADJoined
            $isOnPremJoined = $dsregcmdOutput -match '.*DomainJoined\s*:\s*YES' -and -not $isAzureADJoined
            $isWorkgroup = -not ($isAzureADJoined -or $isHybridJoined -or $isOnPremJoined)

            # Determine MDM enrollment status
            $isMDMEnrolled = $dsregcmdOutput -match '.*MDMUrl\s*:\s*(https://manage\.microsoft\.com|https://enrollment\.manage\.microsoft\.com)'

            # Log the parsed results
            Write-EnhancedLog -Message "Join status parsed: Workgroup: $isWorkgroup, AzureAD: $isAzureADJoined, Hybrid: $isHybridJoined, OnPrem: $isOnPremJoined" -Level "INFO"
            Write-EnhancedLog -Message "MDM enrollment status: $isMDMEnrolled" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error while parsing dsregcmd output: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Returning parsed device status" -Level "INFO"
        return @{
            IsWorkgroup     = $isWorkgroup
            IsAzureADJoined = $isAzureADJoined
            IsHybridJoined  = $isHybridJoined
            IsOnPremJoined  = $isOnPremJoined
            IsMDMEnrolled   = $isMDMEnrolled
        }
    }
}


#Here is an example for a decision-making tree

# # Main script execution block
# $dsregStatus = Get-DSRegStatus

# # Determine and output the join status
# if ($dsregStatus.IsWorkgroup) {
#     Write-Output "Device is Workgroup joined (not Azure AD, Hybrid, or On-prem Joined)."
# } elseif ($dsregStatus.IsAzureADJoined -and -not $dsregStatus.IsHybridJoined) {
#     Write-Output "Device is Azure AD Joined."
# } elseif ($dsregStatus.IsHybridJoined) {
#     Write-Output "Device is Hybrid Joined (both On-prem and Azure AD Joined)."
# } elseif ($dsregStatus.IsOnPremJoined) {
#     Write-Output "Device is On-prem Joined only."
# }

# # Determine and output the MDM enrollment status
# if ($dsregStatus.IsMDMEnrolled) {
#     Write-Output "Device is Intune Enrolled."
# } else {
#     Write-Output "Device is NOT Intune Enrolled."
# }

# # Exit code based on Azure AD and MDM status
# if ($dsregStatus.IsAzureADJoined -and -not $dsregStatus.IsHybridJoined -and $dsregStatus.IsMDMEnrolled) {
#     Write-Output "Device is Azure AD Joined and Intune Enrolled. No migration needed."
#     exit 0 # Do not migrate: Device is Azure AD Joined and Intune Enrolled
# } else {
#     # Migrate: All other cases where the device is not 100% Azure AD joined or is hybrid/on-prem joined
#     exit 1
# }