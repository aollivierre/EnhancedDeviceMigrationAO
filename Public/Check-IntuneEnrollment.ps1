# Function to check Intune enrollment status
function Check-IntuneEnrollment {
    param (
        [string]$OMADMPath,
        [string]$EnrollmentBasePath,
        [string]$MSDMProviderID
    )

    Write-EnhancedLog -Message "Checking Intune enrollment status from registry path $OMADMPath" -Level "INFO"
    $Account = (Get-ItemProperty -Path $OMADMPath -ErrorAction SilentlyContinue).PSChildName
    if ($null -eq $Account) {
        Write-EnhancedLog -Message "No Intune enrollment account found at path $OMADMPath" -Level "WARNING"
        return $null
    }

    Write-EnhancedLog -Message "Enrollment account detected: $Account" -Level "INFO"
    $EnrollmentPath = "$EnrollmentBasePath\$Account"

    Write-EnhancedLog -Message "Checking UPN and ProviderID at enrollment path: $EnrollmentPath" -Level "INFO"
    $EnrollmentUPN = (Get-ItemProperty -Path $EnrollmentPath -ErrorAction SilentlyContinue).UPN
    $ProviderID = (Get-ItemProperty -Path $EnrollmentPath -ErrorAction SilentlyContinue).ProviderID

    if (-not $EnrollmentUPN) {
        Write-EnhancedLog -Message "Enrollment UPN not found at $EnrollmentPath" -Level "WARNING"
        return $null
    }

    if ($ProviderID -ne $MSDMProviderID) {
        Write-EnhancedLog -Message "ProviderID does not match the expected value at $EnrollmentPath" -Level "WARNING"
        return $null
    }

    return $Account
}
