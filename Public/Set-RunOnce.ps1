# function Set-RunOnce {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$ScriptPath,
        
#         [Parameter(Mandatory = $true)]
#         [string]$RunOnceKey,
        
#         [Parameter(Mandatory = $true)]
#         [string]$PowershellPath,
        
#         [Parameter(Mandatory = $true)]
#         [string]$ExecutionPolicy,
        
#         [Parameter(Mandatory = $true)]
#         [string]$RunOnceName
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Set-RunOnce function" -Level "INFO"
#         Log-Params -Params @{
#             ScriptPath      = $ScriptPath
#             RunOnceKey      = $RunOnceKey
#             PowershellPath  = $PowershellPath
#             ExecutionPolicy = $ExecutionPolicy
#             RunOnceName     = $RunOnceName
#         }
#     }

#     Process {
#         try {
#             Write-EnhancedLog -Message "Setting RunOnce script" -Level "INFO"
#             $RunOnceValue = "$PowershellPath -executionPolicy $ExecutionPolicy -File $ScriptPath"
#             Set-ItemProperty -Path $RunOnceKey -Name $RunOnceName -Value $RunOnceValue -Verbose
#         } catch {
#             Write-EnhancedLog -Message "An error occurred while setting RunOnce script: $($_.Exception.Message)" -Level "ERROR"
#             Handle-Error -ErrorRecord $_
#         }
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Set-RunOnce function" -Level "INFO"
#     }
# }

# # # Example usage with splatting
# # $SetRunOnceParams = @{
# #     ScriptPath      = "C:\YourScriptPath.ps1"
# #     RunOnceKey      = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
# #     PowershellPath  = "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe"
# #     ExecutionPolicy = "Unrestricted"
# #     RunOnceName     = "NextRun"
# # }

# # Set-RunOnce @SetRunOnceParams







function Set-RunOnce {
    <#
    .SYNOPSIS
    Sets a RunOnce registry key to execute a specified script on the next system startup.

    .DESCRIPTION
    The Set-RunOnce function sets a RunOnce registry key to execute a specified PowerShell script on the next system startup. This can be useful for scheduling post-reboot tasks.

    .PARAMETER ScriptPath
    The path to the PowerShell script to be executed on the next system startup.

    .PARAMETER RunOnceKey
    The registry key path for the RunOnce entry.

    .PARAMETER PowershellPath
    The path to the PowerShell executable.

    .PARAMETER ExecutionPolicy
    The execution policy for running the PowerShell script.

    .PARAMETER RunOnceName
    The name of the RunOnce entry.

    .EXAMPLE
    $params = @{
        ScriptPath      = "C:\ProgramData\AADMigration\Scripts\PostRunOnce2.ps1"
        RunOnceKey      = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        PowershellPath  = "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe"
        ExecutionPolicy = "Unrestricted"
        RunOnceName     = "NextRun"
    }
    Set-RunOnce @params
    Sets the RunOnce registry key to execute the specified script on the next system startup.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [string]$RunOnceKey,
        
        [Parameter(Mandatory = $true)]
        [string]$PowershellPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ExecutionPolicy,
        
        [Parameter(Mandatory = $true)]
        [string]$RunOnceName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Set-RunOnce function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
        # Log-Params -Params @{
        #     ScriptPath      = $ScriptPath
        #     RunOnceKey      = $RunOnceKey
        #     PowershellPath  = $PowershellPath
        #     ExecutionPolicy = $ExecutionPolicy
        #     RunOnceName     = $RunOnceName
        # }
    }

    Process {
        try {
            # Validate script path
            if (-not (Test-Path -Path $ScriptPath)) {
                Throw "Script file not found: $ScriptPath"
            }

            Write-EnhancedLog -Message "Setting RunOnce registry key for script: $ScriptPath" -Level "INFO"
            $RunOnceValue = "$PowershellPath -executionPolicy $ExecutionPolicy -File $ScriptPath"

            $params = @{
                Path  = $RunOnceKey
                Name  = $RunOnceName
                Value = $RunOnceValue
            }

            Set-ItemProperty @params
            Write-EnhancedLog -Message "RunOnce registry key set successfully." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Set-RunOnce function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Set-RunOnce function" -Level "Notice"
    }
}

# # Example usage with splatting
# $params = @{
#     ScriptPath      = "C:\ProgramData\AADMigration\Scripts\PostRunOnce2.ps1"
#     RunOnceKey      = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
#     PowershellPath  = "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe"
#     ExecutionPolicy = "Unrestricted"
#     RunOnceName     = "NextRun"
# }
# Set-RunOnce @params
