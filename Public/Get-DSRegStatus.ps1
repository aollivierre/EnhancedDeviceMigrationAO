function Get-DSRegStatus {
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

            # Log the full dsregcmd output for debugging purposes
            Write-EnhancedLog -Message "Full dsregcmd output: $dsregcmdOutput" -Level "DEBUG"

            # Parse dsregcmd output to determine join status
            Write-EnhancedLog -Message "Parsing dsregcmd output" -Level "INFO"

            # Split the output into lines for easier parsing
            $outputLines = $dsregcmdOutput -split "`r`n"

            # Extract values
            $isAzureADJoined = if ($outputLines -match 'AzureAdJoined\s*:\s*YES') { $true } else { $false }
            $isHybridJoined = if (($outputLines -match 'DomainJoined\s*:\s*YES') -and $isAzureADJoined) { $true } else { $false }
            $isOnPremJoined = if (($outputLines -match 'DomainJoined\s*:\s*YES') -and -not $isAzureADJoined) { $true } else { $false }
            $isWorkgroup = -not ($isAzureADJoined -or $isHybridJoined -or $isOnPremJoined)

            # Extract MDM enrollment URL if present by iterating over each line
            $mdmUrl = $null
            foreach ($line in $outputLines) {
                if ($line -match 'MDMUrl\s*:\s*(https://[\S]+)') {
                    $isMDMEnrolled = $true
                    $mdmUrl = $matches[1]  # Extract the URL from the match
                    break  # Exit the loop once the MDM URL is found
                }
            }

            if (-not $isMDMEnrolled) {
                $isMDMEnrolled = $false
                Write-EnhancedLog -Message "MDM URL not found in dsregcmd output." -Level "INFO"
            }

            # Log the parsed results
            Write-EnhancedLog -Message "Join status parsed: Workgroup: $isWorkgroup, AzureAD: $isAzureADJoined, Hybrid: $isHybridJoined, OnPrem: $isOnPremJoined" -Level "INFO"
            Write-EnhancedLog -Message "MDM enrollment status: $isMDMEnrolled, MDM URL: $mdmUrl" -Level "INFO"
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
            MDMUrl          = $mdmUrl
        }
    }
}


# # Example usage to print out the values
# $dsregStatus = Get-DSRegStatus

# # Output to the console
# Write-Host "Device Join Status:"
# Write-Host "-------------------"
# Write-Host "Is Workgroup: " $dsregStatus.IsWorkgroup
# Write-Host "Is Azure AD Joined: " $dsregStatus.IsAzureADJoined
# Write-Host "Is Hybrid Joined: " $dsregStatus.IsHybridJoined
# Write-Host "Is On-prem Joined: " $dsregStatus.IsOnPremJoined
# Write-Host "MDM Enrollment: " ($dsregStatus.IsMDMEnrolled ? "Yes" : "No")
# if ($dsregStatus.MDMUrl) {
#     Write-Host "MDM URL: " $dsregStatus.MDMUrl
# }


# # Example usage to print out the values
# $dsregStatus = Get-DSRegStatus

# # Output to the console
# Write-Host "Device Join Status:"
# Write-Host "-------------------"
# Write-Host "Is Workgroup: " $dsregStatus.IsWorkgroup
# Write-Host "Is Azure AD Joined: " $dsregStatus.IsAzureADJoined
# Write-Host "Is Hybrid Joined: " $dsregStatus.IsHybridJoined
# Write-Host "Is On-prem Joined: " $dsregStatus.IsOnPremJoined
# Write-Host "MDM Enrollment: " ($dsregStatus.IsMDMEnrolled ? "Yes" : "No")
# if ($dsregStatus.MDMUrl) {
#     Write-Host "MDM URL: " $dsregStatus.MDMUrl
# }



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