
function Validate-PPKGInstallation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PPKGName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Validate-PPKGInstallation function for $PPKGName" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Validate the PPKG installation using Get-ProvisioningPackage
            $ppkgInfo = Get-ProvisioningPackage -AllInstalledPackages | Where-Object { $_.PackageId -like "*$PPKGName*" }
            
            if ($ppkgInfo) {
                Write-EnhancedLog -Message "Validation successful: PPKG $PPKGName is installed" -Level "INFO"
                return $true
            }
            else {
                Write-EnhancedLog -Message "Validation failed: PPKG $PPKGName is not installed" -Level "ERROR"
                return $false
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during PPKG validation: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Validate-PPKGInstallation function" -Level "NOTICE"
    }
}
