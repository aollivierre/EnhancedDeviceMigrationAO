function Remove-Hybrid {
    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting Remove-Hybrid function" -Level "INFO"
    }

    Process {
        try {
          
            # $Dsregcmd = New-Object PSObject
            # Dsregcmd /status | Where-Object { $_ -match ' : ' } | ForEach-Object {
            #     $Item = $_.Trim() -split '\s:\s'
            #     $Dsregcmd | Add-Member -MemberType NoteProperty -Name $($Item[0] -replace '[:\s]', '') -Value $Item[1] -ErrorAction SilentlyContinue
            # }

            # $AzureADJoined = $Dsregcmd.AzureAdJoined

            Write-EnhancedLog -Message "Checking if device is Hyrbid Azure AD joined" -Level "INFO"

            # Main script execution block
            $dsregStatus = Get-DSRegStatus

            # Determine and output the join status
            if ($dsregStatus.IsWorkgroup) {
                Write-EnhancedLog -Message "Device is Workgroup joined (not Azure AD, Hybrid, or On-prem Joined)."
            }
            elseif ($dsregStatus.IsAzureADJoined -and -not $dsregStatus.IsHybridJoined) {
                Write-EnhancedLog -Message "Device is Azure AD Joined."
            }
            elseif ($dsregStatus.IsHybridJoined) {
                Write-EnhancedLog -Message "Device is Hybrid Joined (both On-prem and Azure AD Joined)."
            }
            elseif ($dsregStatus.IsOnPremJoined) {
                Write-EnhancedLog -Message "Device is On-prem Joined only."
            }

            # Determine and output the MDM enrollment status
            if ($dsregStatus.IsMDMEnrolled) {
                Write-EnhancedLog -Message "Device is Intune Enrolled."
            }
            else {
                Write-EnhancedLog -Message "Device is NOT Intune Enrolled."
            }

            # Exit code based on Azure AD and MDM status
            if ($dsregStatus.IsAzureADJoined -and -not $dsregStatus.IsHybridJoined -and $dsregStatus.IsMDMEnrolled) {
                Write-EnhancedLog -Message "Device is Azure AD Joined and Intune Enrolled. No migration needed." -Level "INFO"
                # exit 0 # Do not migrate: Device is Azure AD Joined and Intune Enrolled
            }
            else {
                # Migrate: All other cases where the device is not 100% Azure AD joined or is hybrid/on-prem joined
                # exit 1
            }

            if ($dsregStatus.IsHybridJoined) {
                Write-EnhancedLog -Message "Device is Hybrid Azure AD joined. Removing hybrid join." -Level "INFO"
                & "C:\Windows\System32\dsregcmd.exe" /leave
            }

        
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while removing hybrid join: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Remove-Hybrid function" -Level "INFO"
    }
}

# Example usage
# Remove-Hybrid
