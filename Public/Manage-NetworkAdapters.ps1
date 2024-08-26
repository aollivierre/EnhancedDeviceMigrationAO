function Manage-NetworkAdapters {
    <#
                .SYNOPSIS
                    Manages the state of network adapters.
                
                .DESCRIPTION
                    This function disables or enables all connected network adapters based on the provided parameter.
                
                .PARAMETER Disable
                    Switch parameter to disable network adapters. If not provided, the function will enable the adapters.
                
                .EXAMPLE
                    Manage-NetworkAdapters -Disable
                
                .EXAMPLE
                    Manage-NetworkAdapters
                
                .NOTES
                    This function is useful for temporarily disabling network connectivity during specific operations.
                #>
    [CmdletBinding()]
    param (
        [switch]$Disable
    )
                
    Begin {
        Write-EnhancedLog -Message "Starting Manage-NetworkAdapters function" -Level "NOTICE"
    }
                
    Process {
        $ConnectedAdapters = Get-NetAdapter | Where-Object { $_.MediaConnectionState -eq "Connected" }
                
        foreach ($Adapter in $ConnectedAdapters) {
            if ($Disable) {
                Write-EnhancedLog -Message "Disabling network adapter $($Adapter.Name)" -Level "INFO"
                Disable-NetAdapter -Name $Adapter.Name -Confirm:$false
            }
            else {
                Write-EnhancedLog -Message "Enabling network adapter $($Adapter.Name)" -Level "INFO"
                Enable-NetAdapter -Name $Adapter.Name -Confirm:$false
            }
        }
    }
                
    End {
        Write-EnhancedLog -Message "Exiting Manage-NetworkAdapters function" -Level "NOTICE"
    }
}