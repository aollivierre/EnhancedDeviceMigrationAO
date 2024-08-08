function Set-ODKFMRegistrySettings {
    <#
    .SYNOPSIS
    Sets OneDrive Known Folder Move (KFM) registry settings.

    .DESCRIPTION
    The Set-ODKFMRegistrySettings function sets specified registry values for OneDrive Known Folder Move (KFM) based on provided tenant ID, registry key path, and an array of registry settings.

    .PARAMETER TenantID
    The tenant ID for OneDrive.

    .PARAMETER RegKeyPath
    The path to the registry key.

    .PARAMETER RegistrySettings
    An array of registry settings to be applied. Each setting should include RegValName, RegValType, and RegValData.

    .EXAMPLE
    $settings = @(
        @{
            RegValName = "KFMValue1"
            RegValType = "String"
            RegValData = "Value1"
        },
        @{
            RegValName = "KFMValue2"
            RegValType = "DWORD"
            RegValData = "1"
        }
    )
    $params = @{
        TenantID         = "your-tenant-id"
        RegKeyPath       = "HKLM:\Software\Policies\Microsoft\OneDrive"
        RegistrySettings = $settings
    }
    Set-ODKFMRegistrySettings @params
    Sets the specified OneDrive KFM registry values.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TenantID,

        [Parameter(Mandatory = $true)]
        [string]$RegKeyPath,

        [Parameter(Mandatory = $true)]
        [array]$RegistrySettings
    )

    Begin {
        Write-EnhancedLog -Message "Starting Set-ODKFMRegistrySettings function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            foreach ($setting in $RegistrySettings) {
                # Define the parameters to be splatted
                $splatParams = @{
                    RegKeyPath = $RegKeyPath
                    RegValName = $setting.RegValName
                    RegValType = $setting.RegValType
                    RegValData = $setting.RegValData
                }

                # Call the function with splatted parameters
                Set-RegistryValue @splatParams
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while setting OneDrive KFM registry values: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Set-ODKFMRegistrySettings function" -Level "Notice"
    }
}


# # Example usage
# $settings = @(
#     @{
#         RegValueName = "KFMValue1"
#         RegValType   = "String"
#         RegValData   = "Value1"
#     },
#     @{
#         RegValueName = "KFMValue2"
#         RegValType   = "DWORD"
#         RegValData   = "1"
#     }
# )
# $params = @{
#     TenantID         = "your-tenant-id"
#     RegKeyPath       = "HKLM:\Software\Policies\Microsoft\OneDrive"
#     RegistrySettings = $settings
# }
# Set-ODKFMRegistrySettings @params


# $TenantID = "YourTenantID"

# $RegistrySettings = @(
#     @{
#         RegValueName = "AllowTenantList"
#         RegValType   = "STRING"
#         RegValData   = $TenantID
#     },
#     @{
#         RegValueName = "SilentAccountConfig"
#         RegValType   = "DWORD"
#         RegValData   = "1"
#     },
#     @{
#         RegValueName = "KFMOptInWithWizard"
#         RegValType   = "STRING"
#         RegValData   = $TenantID
#     },
#     @{
#         RegValueName = "KFMSilentOptIn"
#         RegValType   = "STRING"
#         RegValData   = $TenantID
#     },
#     @{
#         RegValueName = "KFMSilentOptInDesktop"
#         RegValType   = "DWORD"
#         RegValData   = "1"
#     },
#     @{
#         RegValueName = "KFMSilentOptInDocuments"
#         RegValType   = "DWORD"
#         RegValData   = "1"
#     },
#     @{
#         RegValueName = "KFMSilentOptInPictures"
#         RegValType   = "DWORD"
#         RegValData   = "1"
#     }
# )

# $SetODKFMRegistrySettingsParams = @{
#     TenantID           = $TenantID
#     RegKeyPath         = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
#     RegistrySettings   = $RegistrySettings
# }

# Set-ODKFMRegistrySettings @SetODKFMRegistrySettingsParams


#optionally you can create an event source here using Create-EventLogSource.ps1