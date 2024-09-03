function Set-RegistryValue {
    <#
    .SYNOPSIS
    Sets a registry value with validation before and after setting the value.

    .DESCRIPTION
    The Set-RegistryValue function sets a registry value at a specified registry path. It validates the value before setting it and ensures it is set correctly after the operation.

    .PARAMETER RegKeyPath
    The path to the registry key.

    .PARAMETER RegValName
    The name of the registry value.

    .PARAMETER RegValType
    The type of the registry value (e.g., String, DWORD).

    .PARAMETER RegValData
    The data to be set for the registry value. It can be a string, an integer, or even an empty string.
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
        [AllowEmptyString()]
        [string]$RegValData
    )

    Begin {
        Write-EnhancedLog -Message "Starting Set-RegistryValue function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        CheckAndElevate
    }

    Process {
        try {
            # Validate before setting the value
            Write-EnhancedLog -Message "Validating registry value before setting" -Level "INFO"
            $validationBefore = Validate-RegistryValue -RegKeyPath $RegKeyPath -RegValName $RegValName -ExpectedValData $RegValData

            if ($validationBefore) {
                Write-EnhancedLog -Message "Registry value $RegValName is already correctly set. No action taken." -Level "INFO"
                return
            }

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
                
                # Validate after setting the value
                Validate-RegistryValue -RegKeyPath $RegKeyPath -RegValName $RegValName -ExpectedValData $RegValData
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

            # Validate after setting the value
            Validate-RegistryValue -RegKeyPath $RegKeyPath -RegValName $RegValName -ExpectedValData $RegValData
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

