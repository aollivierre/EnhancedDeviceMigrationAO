function Validate-RegistryValue {
    <#
    .SYNOPSIS
    Validates that a registry value is set correctly.

    .DESCRIPTION
    The Validate-RegistryValue function checks whether a registry value matches the expected data.

    .PARAMETER RegKeyPath
    The path to the registry key.

    .PARAMETER RegValName
    The name of the registry value.

    .PARAMETER ExpectedValData
    The expected data of the registry value.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RegKeyPath,

        [Parameter(Mandatory = $true)]
        [string]$RegValName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$ExpectedValData
    )

    Begin {
        Write-EnhancedLog -Message "Starting Validate-RegistryValue function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            $CurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $RegValName
            if ($CurrentValue -eq $ExpectedValData) {
                Write-EnhancedLog -Message "Registry value: $RegValName is set correctly with data: $ExpectedValData" -Level "INFO"
                return $true
            }
            else {
                Write-EnhancedLog -Message "Registry value: $RegValName is not set correctly. Expected: $ExpectedValData, Found: $CurrentValue" -Level "WARNING"
                return $false
            }
        }
        catch {
            Write-EnhancedLog -Message "Registry value: $RegValName not found at $RegKeyPath" -Level "WARNING"
            return $false
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Validate-RegistryValue function" -Level "Notice"
    }
}

# Example usage:
# $params = @{
#     RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
#     RegValName = "AutoAdminLogon"
#     RegValType = "DWORD"
#     RegValData = "0"
# }
# Set-RegistryValue @params
