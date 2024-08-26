function PostRunOnce-Phase2EscrowBitlocker {
    <#
    .SYNOPSIS
    Executes post-run operations for the second phase of the migration process.

    .DESCRIPTION
    The PostRunOnce2 function blocks user input, displays a migration in progress form, creates a scheduled task for post-migration cleanup, escrows the BitLocker recovery key, sets various registry values, and optionally restarts the computer.

    .PARAMETER ImagePath
    The path to the image file to be displayed on the migration progress form.

    .PARAMETER TaskPath
    The path of the task in Task Scheduler.

    .PARAMETER TaskName
    The name of the scheduled task.

    .PARAMETER ScriptPath
    The path to the PowerShell script to be executed by the scheduled task.

    .PARAMETER BitlockerDrives
    An array of drive letters for the BitLocker protected drives. The BitLocker recovery key for each drive will be escrowed as part of the process.

    .PARAMETER RegistrySettings
    A hashtable of registry settings to be applied. The hashtable should be structured with registry paths as keys, and each path should contain another hashtable with the registry value name, type, and data.

    .PARAMETER RebootAfterCompletion
    A switch parameter that controls whether the computer should be restarted after completing all post-run operations. If not specified, the computer will be restarted by default.

    .EXAMPLE
    $params = @{
        ImagePath = "C:\ProgramData\AADMigration\Files\MigrationInProgress.bmp"
        TaskPath = "AAD Migration"
        TaskName = "Run Post-migration cleanup"
        ScriptPath = "C:\ProgramData\AADMigration\Scripts\PostRunOnce3.ps1"
        BitlockerDrives = @("C:", "D:")
        RegistrySettings = @{
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" = @{
                "AutoAdminLogon" = @{
                    "Type" = "DWORD"
                    "Data" = "0"
                }
            }
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" = @{
                "dontdisplaylastusername" = @{
                    "Type" = "DWORD"
                    "Data" = "1"
                }
                "legalnoticecaption" = @{
                    "Type" = "String"
                    "Data" = "Migration Completed"
                }
                "legalnoticetext" = @{
                    "Type" = "String"
                    "Data" = "This PC has been migrated to Azure Active Directory. Please log in to Windows using your email address and password."
                }
            }
        }
        RebootAfterCompletion = $false
    }
    PostRunOnce2 @params
    Executes the post-run operations without restarting the computer after completion.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string[]]$BitlockerDrives,

        [Parameter(Mandatory = $true)]
        [hashtable]$RegistrySettings,

        [Parameter(Mandatory = $false)]
        [switch]$RebootAfterCompletion = $true
    )

    Begin {
        Write-EnhancedLog -Message "Starting PostRunOnce2 function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Block user input
            Write-EnhancedLog -Message "Blocking user input" -Level "INFO"
            $blockParams = @{
                Block = $true
            }
            Block-UserInput @blockParams
            Write-EnhancedLog -Message "User input blocked" -Level "INFO"

            # Show migration in progress form
            Write-EnhancedLog -Message "Displaying migration in progress form with image $ImagePath" -Level "INFO"
            $formParams = @{
                ImagePath = $ImagePath
            }
            Show-MigrationInProgressForm @formParams
            Write-EnhancedLog -Message "Migration in progress form displayed" -Level "INFO"

            # Create scheduled task for post-migration cleanup
            Write-EnhancedLog -Message "Creating scheduled task $TaskName at $TaskPath" -Level "INFO"
            $CreatePostMigrationCleanupTaskParams = @{
                TaskPath   = $TaskPath
                TaskName   = $TaskName
                ScriptPath = $ScriptPath
            }
            Create-PostMigrationCleanupTask @CreatePostMigrationCleanupTaskParams
            Write-EnhancedLog -Message "Scheduled task $TaskName created" -Level "INFO"

            $DBG

            # Escrow BitLocker recovery key for each drive
            foreach ($drive in $BitlockerDrives) {
                Write-EnhancedLog -Message "Escrowing BitLocker key for drive $drive" -Level "INFO"
                $escrowParams = @{
                    DriveLetter = $drive
                }
                Escrow-BitLockerKey @escrowParams
                Write-EnhancedLog -Message "BitLocker key for drive $drive escrowed" -Level "INFO"
            }

            # Set registry values
            foreach ($regPath in $RegistrySettings.Keys) {
                foreach ($regName in $RegistrySettings[$regPath].Keys) {
                    $regSetting = $RegistrySettings[$regPath][$regName]
                    Write-EnhancedLog -Message "Setting registry value $regName at $regPath" -Level "INFO"
                    $regParams = @{
                        RegKeyPath = $regPath
                        RegValName = $regName
                        RegValType = $regSetting["Type"]
                        RegValData = $regSetting["Data"]
                    }
                    Set-RegistryValue @regParams
                    Write-EnhancedLog -Message "Registry value $regName at $regPath set" -Level "INFO"
                }
            }

            # Unblock user input and close form
            Write-EnhancedLog -Message "Unblocking user input and closing migration progress form" -Level "INFO"
            Block-UserInput -Block $false

            # Optionally reboot the machine
            if ($RebootAfterCompletion) {
                Write-EnhancedLog -Message "Rebooting computer after successful completion" -Level "INFO"
                Restart-Computer
            }
            else {
                Write-EnhancedLog -Message "Skipping reboot as per user request" -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in PostRunOnce2 function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting PostRunOnce2 function" -Level "Notice"
    }
}
