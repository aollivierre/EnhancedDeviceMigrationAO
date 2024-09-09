function Install-PPKG {
    <#
    .SYNOPSIS
    Installs a provisioning package (PPKG) with validation and logging.

    .DESCRIPTION
    The Install-PPKG function installs a provisioning package (PPKG) from a specified path. If the provisioning package is already installed, it will force remove it before reinstalling. It logs the installation process, validates the installation, and handles errors gracefully.

    .PARAMETER PPKGPath
    The full path to the provisioning package (PPKG) to be installed.

    .EXAMPLE
    $params = @{
        PPKGPath     = "C:\ProgramData\AADMigration\MyProvisioningPackage.ppkg"
    }
    Install-PPKG @params
    Installs the specified provisioning package and logs the installation.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the full path to the PPKG file.")]
        [ValidateNotNullOrEmpty()]
        [string]$PPKGPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Install-PPKG function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Validate PPKG file exists
        if (-not (Test-Path -Path $PPKGPath)) {
            throw "Provisioning package file not found: $PPKGPath"
        }


        # Extract just the file name from the PPKG path (without extension)
        $ppkgFileName = [System.IO.Path]::GetFileNameWithoutExtension($PPKGPath)

        # Check if the PPKG is already installed
        Write-EnhancedLog -Message "Validating if provisioning package is already installed." -Level "INFO"
        $isInstalled = Validate-PPKGInstallation -PPKGName $ppkgFileName
  

        if ($isInstalled) {
            Remove-InstalledPPKG -PackageName $ppkgFileName
        }
        


        # Wait-Debugger
    }

    Process {
        try {
            Write-EnhancedLog -Message "Installing provisioning package: $PPKGPath" -Level "INFO"

            # Get current timestamp
            $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")

            # Create the dynamic log directory path based on PPKGPath and timestamp
            $logDir = "C:\logs\PPKG_EJ_Bulk_Enrollment\$ppkgFileName"
            $logFile = "$logDir\InstallLog_$timestamp.etl"

            # Check if the log directory exists, and create it if not
            if (-not (Test-Path $logDir)) {
                Write-EnhancedLog -Message "Log directory does not exist. Creating directory: $logDir" -Level "INFO"
                New-Item -Path $logDir -ItemType Directory -Force
            }

            # Set the Install-ProvisioningPackage parameters with the dynamic log file path
            $InstallProvisioningPackageParams = @{
                PackagePath   = $PPKGPath
                ForceInstall  = $true
                QuietInstall  = $true
                LogsDirectory = $logFile
            }

            # Log the parameters being passed to Install-ProvisioningPackage
            Write-EnhancedLog -Message "Starting installation of provisioning package with the following parameters:" -Level "INFO"
            Log-Params -Params $InstallProvisioningPackageParams

            # Install the provisioning package
            Install-ProvisioningPackage @InstallProvisioningPackageParams
            Write-EnhancedLog -Message "Successfully installed provisioning package: $PPKGPath" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error installing provisioning package: $($_.Exception.Message)" -Level "ERROR"
            Write-EnhancedLog -Message "Did you check that the Package_GUID Account in Entra is excluded from All Conditional Access Policies" -Level "INFO"
            Handle-Error -ErrorRecord $_
            throw
        }
        Finally {
            # Always log exit and cleanup actions
            Write-EnhancedLog -Message "Exiting Install-PPKG function" -Level "Notice"
        }
    }

    End {
        Write-EnhancedLog -Message "Validating provisioning package installation" -Level "INFO"
        $isInstalled = Validate-PPKGInstallation -PPKGName $ppkgFileName
        if ($isInstalled) {
            Write-EnhancedLog -Message "Provisioning package $PPKGPath installed successfully" -Level "INFO"
        }
        else {
            Write-EnhancedLog -Message "Provisioning package $PPKGPath installation failed" -Level "ERROR"
            throw "Provisioning package $PPKGPath installation could not be validated"
        }
    }
}

# # Example usage
# $params = @{
#     PPKGPath     = "C:\ProgramData\AADMigration\Files\ICTC_Project_2_Aug_29_2024\ICTC_Project_2.ppkg"
# }
# Install-PPKG @params