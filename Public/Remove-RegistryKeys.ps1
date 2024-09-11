
# Function to remove registry keys
function Remove-RegistryKeys {
    param (
        [string[]]$RegistryPathsToRemove,
        [string]$Account
    )

    Write-EnhancedLog -Message "Attempting to remove registry keys associated with enrollment" -Level "INFO"
    foreach ($RegistryPath in $RegistryPathsToRemove) {
        Write-EnhancedLog -Message "Removing registry path: $RegistryPath\$Account" -Level "INFO"
        Remove-Item -Path "$RegistryPath\$Account" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-EnhancedLog -Message "Registry keys removed successfully (if any existed)" -Level "INFO"

    return [PSCustomObject]@{
        Action = "Remove Registry Keys"
        Path   = "$RegistryPath\$Account"
        Status = "Success"
    }
}
