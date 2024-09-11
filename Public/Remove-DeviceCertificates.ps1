# Function to remove device certificates
function Remove-DeviceCertificates {
    param (
        [string]$CertLocalMachinePath,
        [string[]]$DeviceCertIssuers
    )

    Write-EnhancedLog -Message "Attempting to remove device certificates with issuers: $DeviceCertIssuers" -Level "INFO"
    $DeviceCerts = Get-ChildItem -Path $CertLocalMachinePath -Recurse
    $IntuneCerts = $DeviceCerts | Where-Object { $DeviceCertIssuers -contains $_.Issuer }
    foreach ($Cert in $IntuneCerts) {
        Write-EnhancedLog -Message "Removing device certificate: $($Cert.Subject)" -Level "INFO"
        $Cert | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    Write-EnhancedLog -Message "Device certificates removed successfully" -Level "INFO"

    return [PSCustomObject]@{
        Action = "Remove Device Certificates"
        Path   = $CertLocalMachinePath
        Status = "Success"
    }
}