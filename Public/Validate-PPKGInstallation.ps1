
function Validate-PPKGInstallation {
    <#
    .SYNOPSIS
    Validates whether a provisioning package (PPKG) is installed on the system.

    .DESCRIPTION
    The Validate-PPKGInstallation function checks if a specified provisioning package (PPKG) is installed on the system by comparing its name with installed packages and validating the `IsInstalled` property. If found and installed, the function returns `$true`, otherwise `$false`.

    .PARAMETER PPKGName
    The name (or partial name) of the provisioning package (PPKG) to validate.

    .EXAMPLE
    # Example: Validate if the "ICTC_Project_2" PPKG is installed
    $ppkgInstalled = Validate-PPKGInstallation -PPKGName "ICTC_Project_2"
    if ($ppkgInstalled) {
        Write-Host "Provisioning package is installed."
    } else {
        Write-Host "Provisioning package is not installed."
    }
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the name of the provisioning package (PPKG) to validate.")]
        [ValidateNotNullOrEmpty()]
        [string]$PPKGName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Validate-PPKGInstallation function for $PPKGName" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Fetch all installed provisioning packages
            Write-EnhancedLog -Message "Fetching all installed provisioning packages..." -Level "INFO"
            $installedPackages = Get-ProvisioningPackage -AllInstalledPackages
    
            # Log the number of installed packages found
            $packageCount = $installedPackages.Count
            Write-EnhancedLog -Message "Found $packageCount installed provisioning packages." -Level "INFO"

            # Check if no packages are found and exit the script
            if ($packageCount -eq 0) {
                Write-EnhancedLog -Message "No provisioning packages found. Exiting script." -Level "WARNING"
                return
            }

    
            # Filter the packages based on the provided PPKG name
            Write-EnhancedLog -Message "Searching for a package matching: *$PPKGName*" -Level "INFO"
    
            $ppkgInfo = $null
            foreach ($package in $installedPackages) {
                Write-EnhancedLog -Message "Checking package: `nPackage ID: $($package.PackageId)`nPackage Name: $($package.PackageName)`nPackage Path: $($package.PackagePath)" -Level "INFO"
    
                # Match on PackageName, but also validate IsInstalled
                if ($package.PackageName -like "*$PPKGName*" -and $package.IsInstalled) {
                    Write-EnhancedLog -Message "Match found and installed: `nPackage ID: $($package.PackageId)`nPackage Name: $($package.PackageName)`nPackage Path: $($package.PackagePath)" -Level "INFO"
                    $ppkgInfo = $package
                    break
                }
                else {
                    Write-EnhancedLog -Message "No match or package not installed: $($package.PackageName)" -Level "INFO"
                }
            }
    
            # Log if a matching package was found or not
            if ($ppkgInfo) {
                Write-EnhancedLog -Message "Provisioning package $($ppkgInfo.PackageName) is installed." -Level "INFO"
                return $true
            }
            else {
                Write-EnhancedLog -Message "No matching installed package found for: *$PPKGName*" -Level "ERROR"
                return $false
            }
        }
        catch {
            # Log and handle any errors encountered during validation
            Write-EnhancedLog -Message "An error occurred during PPKG validation: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Validate-PPKGInstallation function for $PPKGName" -Level "NOTICE"
    }
}

# # Example: Validate if a specific provisioning package is installed
# $ppkgInstalled = Validate-PPKGInstallation -PPKGName "MyProvisioningPackage"
# if ($ppkgInstalled) {
#     Write-Host "Provisioning package is installed."
# }
# else {
#     Write-Host "Provisioning package is not installed."
# }
