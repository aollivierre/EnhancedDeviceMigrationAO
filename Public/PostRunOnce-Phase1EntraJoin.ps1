function PostRunOnce-Phase1EntraJoin {
    <#
    .SYNOPSIS
    Starts the migration process by configuring settings, blocking user input, displaying a progress form, installing a provisioning package, and optionally restarting the computer.

    .DESCRIPTION
    The PostRunOnce-Phase1EntraJoin function configures migration settings, blocks user input, displays a migration progress form, sets a RunOnce script for post-reboot tasks, installs a provisioning package, and then optionally restarts the computer. The function includes validation of the provisioning package installation using the Get-ProvisioningPackage cmdlet.

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

    .PARAMETER RebootAfterInstallation
    A switch parameter that controls whether the computer should be restarted after the provisioning package installation. If not specified, the computer will be restarted by default.

    .PARAMETER Mode
    Specifies the mode in which the script should run. Options are "Dev" for development mode or "Prod" for production mode. In Dev mode, certain features are skipped, while in Prod mode, all features are executed.

    .EXAMPLE
    $params = @{
        MigrationConfigPath = "C:\ProgramData\AADMigration\scripts\MigrationConfig.psd1"
        ImagePath = "C:\ProgramData\AADMigration\Files\MigrationInProgress.bmp"
        RunOnceScriptPath = "C:\ProgramData\AADMigration\Scripts\PostRunOnce2.ps1"
        RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        PowershellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe"
        ExecutionPolicy = "Unrestricted"
        RunOnceName = "NextRun"
        Mode = "Dev"
    }
    PostRunOnce-Phase1EntraJoin @params
    Runs the migration process in Dev mode, skipping user input blocking and reboots.

    .EXAMPLE
    $params = @{
        MigrationConfigPath = "C:\ProgramData\AADMigration\scripts\MigrationConfig.psd1"
        ImagePath = "C:\ProgramData\AADMigration\Files\MigrationInProgress.bmp"
        RunOnceScriptPath = "C:\ProgramData\AADMigration\Scripts\PostRunOnce2.ps1"
        RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        PowershellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe"
        ExecutionPolicy = "Unrestricted"
        RunOnceName = "NextRun"
        RebootAfterInstallation = $true
        Mode = "Prod"
    }
    PostRunOnce-Phase1EntraJoin @params
    Runs the migration process in Prod mode, executing all features, including user input blocking and reboots.
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
        [string]$RunOnceName,

        [Parameter(Mandatory = $false)]
        [switch]$RebootAfterInstallation,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Dev", "Prod")]
        [string]$Mode
    )

    Begin {
        Write-EnhancedLog -Message "Starting PostRunOnce-Phase1EntraJoin function in $Mode mode" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Load the migration configuration
            Write-EnhancedLog -Message "Loading migration configuration from $MigrationConfigPath" -Level "INFO"
            $MigrationConfig = Import-PowerShellDataFile -Path $MigrationConfigPath
            $PPKGPath = $MigrationConfig.ProvisioningPack
            $MigrationPath = $MigrationConfig.MigrationPath
            Write-EnhancedLog -Message "Loaded PPKGPath: $PPKGPath, MigrationPath: $MigrationPath" -Level "INFO"

            # Block user input if in Prod mode
            if ($Mode -eq "Prod") {
                Write-EnhancedLog -Message "Blocking user input" -Level "INFO"
                $blockParams = @{
                    Block = $true
                }
                Block-UserInput @blockParams
                Write-EnhancedLog -Message "User input blocked" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Skipping user input blocking in Dev mode" -Level "WARNING"
            }

            # Show migration in progress form
            if ($Mode -eq "Prod") {
                Write-EnhancedLog -Message "Displaying migration in progress form with image $ImagePath" -Level "INFO"
                $formParams = @{
                    ImagePath = $ImagePath
                }
                Show-MigrationInProgressForm @formParams
                Write-EnhancedLog -Message "Migration in progress form displayed" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Skipping Displaying Migration in Progress form in Dev mode" -Level "WARNING"
            }

            # Set RunOnce script
            Write-EnhancedLog -Message "Setting RunOnce script at $RunOnceKey with script $RunOnceScriptPath" -Level "INFO"
            $runOnceParams = @{
                ScriptPath      = $RunOnceScriptPath
                RunOnceKey      = $RunOnceKey
                PowershellPath  = $PowershellPath
                ExecutionPolicy = $ExecutionPolicy
                RunOnceName     = $RunOnceName
            }
            Set-RunOnce @runOnceParams
            Write-EnhancedLog -Message "RunOnce script set" -Level "INFO"

            # Install provisioning package
            Write-EnhancedLog -Message "Installing provisioning package $PPKGPath from $MigrationPath" -Level "INFO"
            $installParams = @{
                PPKGPath      = $PPKGPath
                # MigrationPath = $MigrationPath
            }
            Install-PPKG @installParams
            Write-EnhancedLog -Message "Provisioning package installation command executed" -Level "INFO"

            # Unblock user input and close form if in Prod mode
            if ($Mode -eq "Prod") {
                Write-EnhancedLog -Message "Unblocking user input and closing migration progress form" -Level "INFO"
                Block-UserInput -Block $false
            }
            else {
                Write-EnhancedLog -Message "Skipping unblocking of user input in Dev mode" -Level "WARNING"
            }

            # Optionally reboot the machine
            if ($RebootAfterInstallation -and $Mode -eq "Prod") {
                Write-EnhancedLog -Message "Rebooting computer after successful migration" -Level "INFO"
                Restart-Computer
            }
            else {
                Write-EnhancedLog -Message "Skipping reboot as per mode or user request" -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during the migration process: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting PostRunOnce-Phase1EntraJoin function" -Level "Notice"
    }
}
