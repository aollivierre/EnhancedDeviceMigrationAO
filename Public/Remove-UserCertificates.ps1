
# Function to remove user certificates
function Remove-UserCertificates {
    param (
        [string]$CertCurrentUserPath,
        [string]$UserCertIssuer
    )

    Write-EnhancedLog -Message "Attempting to remove user certificates with issuer: $UserCertIssuer" -Level "INFO"
    $UserCerts = Get-ChildItem -Path $CertCurrentUserPath -Recurse
    $IntuneCerts = $UserCerts | Where-Object { $_.Issuer -eq $UserCertIssuer }
    foreach ($Cert in $IntuneCerts) {
        Write-EnhancedLog -Message "Removing certificate: $($Cert.Subject)" -Level "INFO"
        $Cert | Remove-Item -Force
    }
    Write-EnhancedLog -Message "User certificates removed successfully" -Level "INFO"

    return [PSCustomObject]@{
        Action = "Remove User Certificates"
        Path   = $CertCurrentUserPath
        Status = "Success"
    }
}