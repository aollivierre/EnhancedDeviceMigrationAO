function Install-PPKG {
    <#
    .SYNOPSIS
    Installs a provisioning package (PPKG).

    .DESCRIPTION
    The Install-PPKG function installs a provisioning package (PPKG) from a specified path. It logs the installation process and handles errors gracefully.

    .PARAMETER PPKGName
    The name of the provisioning package to be installed.

    .PARAMETER MigrationPath
    The path to the migration files directory containing the provisioning package.

    .EXAMPLE
    $params = @{
        PPKGName     = "MyProvisioningPackage.ppkg"
        MigrationPath = "C:\ProgramData\AADMigration"
    }
    Install-PPKG @params
    Installs the specified provisioning package.
    #>

    [CmdletBinding()]
    param (

        # [Parameter(Mandatory = $true)]
        # [string]$PPKPath,

        [Parameter(Mandatory = $true)]
        [string]$PPKGName,

        [Parameter(Mandatory = $true)]
        [string]$MigrationPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Install-PPKG function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # $ppkgPath = Join-Path -Path $MigrationPath -ChildPath "Files\$PPKGName"

            if (-not (Test-Path -Path $PPKGName)) {
                Throw "Provisioning package file not found: $PPKGName"
            }

            Write-EnhancedLog -Message "Installing provisioning package: $PPKGName" -Level "INFO"

            $DBG

            $params = @{
                PackagePath  = $ppkgPath
                ForceInstall = $true
                QuietInstall = $true
            }

            Install-ProvisioningPackage @params
            # Write-EnhancedLog -Message "Provisioning package installed successfully." -Level "INFO"

            # Validate provisioning package installation
            Write-EnhancedLog -Message "Validating provisioning package installation" -Level "INFO"
            $isInstalled = Validate-PPKGInstallation -PPKGName $PPKGName
            if ($isInstalled) {
                Write-EnhancedLog -Message "Provisioning package $PPKGName installed successfully" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Provisioning package $PPKGName installation failed" -Level "ERROR"
                throw "Provisioning package $PPKGName installation could not be validated"
            }

        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Install-PPKG function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Install-PPKG function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     PPKGName     = "MyProvisioningPackage.ppkg"
#     MigrationPath = "C:\ProgramData\AADMigration"
# }
# Install-PPKG @params
