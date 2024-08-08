# function Set-RegistryValue {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$RegKeyPath,
#         [Parameter(Mandatory = $true)]
#         [string]$RegValueName,
#         [Parameter(Mandatory = $true)]
#         [string]$RegValType,
#         [Parameter(Mandatory = $true)]
#         [string]$RegValData
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Set-RegistryValue function" -Level "INFO"
#         Log-Params -Params @{
#             RegKeyPath = $RegKeyPath
#             RegValueName = $RegValueName
#             RegValType = $RegValType
#             RegValData = $RegValData
#         }
#     }

#     Process {
#         try {
#             # Check if registry key exists, create if it does not
#             if (-not (Test-Path -Path $RegKeyPath)) {
#                 Write-EnhancedLog -Message "Registry key path does not exist, creating: $RegKeyPath" -Level "INFO"
#                 New-Item -Path $RegKeyPath -Force | Out-Null
#             } else {
#                 Write-EnhancedLog -Message "Registry key path exists: $RegKeyPath" -Level "INFO"
#             }

#             # Check if registry value exists and its current value
#             $currentValue = $null
#             try {
#                 $currentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $RegValueName
#             } catch {
#                 Write-EnhancedLog -Message "Registry value not found, setting new value: $RegValueName" -Level "INFO"
#                 New-ItemProperty -Path $RegKeyPath -Name $RegValueName -PropertyType $RegValType -Value $RegValData -Force
#             }

#             # If value exists but data is incorrect, update the value
#             if ($currentValue -ne $RegValData) {
#                 Write-EnhancedLog -Message "Updating registry value: $RegValueName with new data: $RegValData" -Level "INFO"
#                 Set-ItemProperty -Path $RegKeyPath -Name $RegValueName -Value $RegValData -Force
#             }
#         } catch {
#             Write-EnhancedLog -Message "An error occurred while processing the Set-RegistryValue function: $($_.Exception.Message)" -Level "ERROR"
#             Handle-Error -ErrorRecord $_
#         }
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Set-RegistryValue function" -Level "INFO"
#     }
# }


# # Example usage
# # Set-RegistryValue -RegKeyPath "HKCU:\Software\MyApp" -RegValueName "MyValue" -RegValType "String" -RegValData "MyData"













function Set-RegistryValue {
    <#
    .SYNOPSIS
    Sets a registry value.

    .DESCRIPTION
    The Set-RegistryValue function sets a registry value at a specified registry path. It creates the registry key if it does not exist and updates the value if it differs from the provided data.

    .PARAMETER RegKeyPath
    The path to the registry key.

    .PARAMETER RegValName
    The name of the registry value.

    .PARAMETER RegValType
    The type of the registry value (e.g., String, DWORD).

    .PARAMETER RegValData
    The data to be set for the registry value.

    .EXAMPLE
    $params = @{
        RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        RegValName = "AutoAdminLogon"
        RegValType = "DWORD"
        RegValData = "0"
    }
    Set-RegistryValue @params
    Sets the AutoAdminLogon registry value to 0.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RegKeyPath,

        [Parameter(Mandatory = $true)]
        [string]$RegValName,

        [Parameter(Mandatory = $true)]
        [string]$RegValType,

        [Parameter(Mandatory = $true)]
        [string]$RegValData
    )

    Begin {
        Write-EnhancedLog -Message "Starting Set-RegistryValue function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Check if running as administrator
        # if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        #     Write-EnhancedLog -Message "Script is not running as administrator. Attempting to elevate." -Level "INFO"
        #     Start-Process -FilePath "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
        #     Exit
        # }

        CheckAndElevate
    }

    Process {
        try {
            # Test to see if registry key exists, if it does not exist create it
            if (-not (Test-Path -Path $RegKeyPath)) {
                New-Item -Path $RegKeyPath -Force | Out-Null
                Write-EnhancedLog -Message "Created registry key: $RegKeyPath" -Level "INFO"
            }

            # Check if value exists and if it needs updating
            try {
                $CurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $RegValName
            }
            catch {
                # If value does not exist, create it
                Set-ItemProperty -Path $RegKeyPath -Name $RegValName -Type $RegValType -Value $RegValData -Force
                Write-EnhancedLog -Message "Created registry value: $RegValName with data: $RegValData" -Level "INFO"
                return
            }

            if ($CurrentValue -ne $RegValData) {
                # If value exists but data is wrong, update the value
                Set-ItemProperty -Path $RegKeyPath -Name $RegValName -Type $RegValType -Value $RegValData -Force
                Write-EnhancedLog -Message "Updated registry value: $RegValName with data: $RegValData" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Registry value: $RegValName already has the correct data: $RegValData" -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Set-RegistryValue function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Set-RegistryValue function" -Level "Notice"
    }
}

# # Example call to the function
# $RegistrySettings = @(
#     @{
#         RegValName = "AllowTenantList"
#         RegValType = "String"
#         RegValData = "b5dae566-ad8f-44e1-9929-5669f1dbb343"
#     }
# )

# foreach ($setting in $RegistrySettings) {
#     # Define the parameters to be splatted
#     $splatParams = @{
#         RegKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
#         RegValName = $setting.RegValName
#         RegValType = $setting.RegValType
#         RegValData = $setting.RegValData
#     }

#     # Call the function with splatted parameters
#     Set-RegistryValue @splatParams
# }


# # Example usage
# $params = @{
#     RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
#     RegValName = "AutoAdminLogon"
#     RegValType = "DWORD"
#     RegValData = "0"
# }
# Set-RegistryValue @params
