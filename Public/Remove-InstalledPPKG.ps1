function Remove-InstalledPPKG {
    <#
    .SYNOPSIS
    Removes an installed provisioning package by its PackageName.

    .DESCRIPTION
    This function checks if a provisioning package is installed based on the provided package name.
    If the package is installed, it retrieves the PackageId and removes it from the system, with detailed
    logging and error handling.

    .PARAMETER PackageName
    The name of the provisioning package to remove.

    .EXAMPLE
    Remove-InstalledPPKG -PackageName "MyProvisioningPackage"
    # Removes the provisioning package with the name "MyProvisioningPackage".
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the name of the provisioning package to remove.")]
        [ValidateNotNullOrEmpty()]
        [string]$PackageName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Remove-InstalledPPKG function for package: $PackageName" -Level "INFO"
    }

    Process {
        try {
            # Write-EnhancedLog -Message "Provisioning package $PackageName is already installed, attempting to remove it." -Level "WARNING"

            # Log the attempt to fetch installed package information
            Write-EnhancedLog -Message "Retrieving installed package information for package: $PackageName" -Level "INFO"

            # Retrieve the correct PackageId from the installed package information
            $installedPackage = Get-ProvisioningPackage -AllInstalledPackages | Where-Object { $_.PackageName -like "*$PackageName*" }

            # Check if the installed package information is found
            if ($installedPackage) {
                $installedPackageId = $installedPackage.PackageId
                Write-EnhancedLog -Message "Found installed package ID: $installedPackageId" -Level "INFO"

                try {
                    # Log the attempt to remove the package
                    Write-EnhancedLog -Message "Attempting to remove provisioning package with ID: $installedPackageId" -Level "INFO"

                    # Remove the installed provisioning package using PackageId
                    Remove-ProvisioningPackage -PackageID $installedPackageId

                    # Log success of removal
                    Write-EnhancedLog -Message "Provisioning package removed successfully with ID: $installedPackageId" -Level "INFO"
                }
                catch {
                    # Log error during package removal
                    Write-EnhancedLog -Message "Error during provisioning package removal using ID $installedPackageId $($_.Exception.Message)" -Level "ERROR"
                    Handle-Error -ErrorRecord $_
                    throw $_
                }
            }
            else {
                # Log if the installed package information could not be found
                Write-EnhancedLog -Message "Error: Unable to find the installed provisioning package with name: $PackageName" -Level "ERROR"
                throw "Provisioning package information not found for removal."
            }
        }
        catch {
            # General error handling for the entire removal process
            Write-EnhancedLog -Message "An error occurred while trying to remove the installed provisioning package: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Remove-InstalledPPKG function for package: $PackageName" -Level "INFO"
    }
}

# Example usage:
# Remove-InstalledPPKG -PackageName "ICTC_Project_2"
