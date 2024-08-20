function Start-MigrationProcess {
    <#
    .SYNOPSIS
    Starts the migration process by configuring settings, blocking user input, displaying a progress form, and installing a provisioning package.

    .DESCRIPTION
    The Start-MigrationProcess function configures migration settings, blocks user input, displays a migration progress form, sets a RunOnce script for post-reboot tasks, installs a provisioning package, and then restarts the computer.

    .PARAMETER MigrationConfigPath
    The path to the migration configuration file.

    .PARAMETER ImagePath
    The path to the image file to be displayed on the migration progress form.

    .PARAMETER RunOnceScriptPath
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
        MigrationConfigPath = "C:\ProgramData\AADMigration\scripts\MigrationConfig.psd1"
        ImagePath = "C:\ProgramData\AADMigration\Files\MigrationInProgress.bmp"
        RunOnceScriptPath = "C:\ProgramData\AADMigration\Scripts\PostRunOnce2.ps1"
        RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        PowershellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe"
        ExecutionPolicy = "Unrestricted"
        RunOnceName = "NextRun"
    }
    Start-MigrationProcess @params
    Starts the migration process.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MigrationConfigPath,

        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

        [Parameter(Mandatory = $true)]
        [string]$RunOnceScriptPath,

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
        Write-EnhancedLog -Message "Starting Start-MigrationProcess function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Start-Transcript -Path "C:\ProgramData\AADMigration\Logs\AD2AADJ-R1.txt" -NoClobber

            $MigrationConfig = Import-LocalizedData -BaseDirectory (Split-Path -Path $MigrationConfigPath) -FileName (Split-Path -Path $MigrationConfigPath -Leaf)
            $PPKGName = $MigrationConfig.ProvisioningPack
            $MigrationPath = $MigrationConfig.MigrationPath

            # Block user input
            $blockParams = @{
                Block = $true
            }
            Block-UserInput @blockParams

            # Show migration in progress form
            $formParams = @{
                ImagePath = $ImagePath
            }
            Show-MigrationInProgressForm @formParams

            # Set RunOnce script
            $runOnceParams = @{
                ScriptPath      = $RunOnceScriptPath
                RunOnceKey      = $RunOnceKey
                PowershellPath  = $PowershellPath
                ExecutionPolicy = $ExecutionPolicy
                RunOnceName     = $RunOnceName
            }
            Set-RunOnce @runOnceParams

            # Install provisioning package
            $installParams = @{
                PPKGName     = $PPKGName
                MigrationPath = $MigrationPath
            }
            Install-PPKG @installParams

            # Stop-Transcript

            # Unblock user input and close form
            Block-UserInput -Block $false

            Restart-Computer
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during the migration process: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Start-MigrationProcess function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     MigrationConfigPath = "C:\ProgramData\AADMigration\scripts\MigrationConfig.psd1"
#     ImagePath = "C:\ProgramData\AADMigration\Files\MigrationInProgress.bmp"
#     RunOnceScriptPath = "C:\ProgramData\AADMigration\Scripts\PostRunOnce2.ps1"
#     RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
#     PowershellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe"
#     ExecutionPolicy = "Unrestricted"
#     RunOnceName = "NextRun"
# }
# Start-MigrationProcess @params
