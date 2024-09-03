function PostRunOnce-Phase2EscrowBitlocker {
    <#
    .SYNOPSIS
    Executes post-run operations for the second phase of the migration process.

    .DESCRIPTION
    The PostRunOnce-Phase2EscrowBitlocker function blocks user input, displays a migration in progress form, creates a scheduled task for post-migration cleanup, escrows the BitLocker recovery key, sets various registry values, and optionally restarts the computer. The actions performed vary depending on the specified mode (Dev or Prod).

    .PARAMETER ImagePath
    The path to the image file to be displayed on the migration progress form.

    .PARAMETER TaskPath
    The path of the task in Task Scheduler.

    .PARAMETER TaskName
    The name of the scheduled task.

    .PARAMETER BitlockerDrives
    An array of drive letters for the BitLocker protected drives. The BitLocker recovery key for each drive will be escrowed as part of the process.

    .PARAMETER RegistrySettings
    A hashtable of registry settings to be applied. The hashtable should be structured with registry paths as keys, and each path should contain another hashtable with the registry value name, type, and data.

    .PARAMETER RebootAfterCompletion
    A switch parameter that controls whether the computer should be restarted after completing all post-run operations. If not specified, the computer will be restarted by default.

    .PARAMETER Mode
    Specifies the mode in which the script should run. Options are "Dev" for development mode or "Prod" for production mode. In Dev mode, certain features are skipped, while in Prod mode, all features are executed.

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
        Mode = "Dev"
    }
    PostRunOnce-Phase2EscrowBitlocker @params
    Executes the post-run operations in Dev mode, skipping user input blocking and reboots.

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
        Mode = "Prod"
    }
    PostRunOnce-Phase2EscrowBitlocker @params
    Executes the post-run operations in Prod mode, including user input blocking and reboots.
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
        [string[]]$BitlockerDrives,

        [Parameter(Mandatory = $true)]
        [hashtable]$RegistrySettings,

        [Parameter(Mandatory = $false)]
        [switch]$RebootAfterCompletion,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Dev", "Prod")]
        [string]$Mode = "Prod"
    )

    Begin {
        Write-EnhancedLog -Message "Starting PostRunOnce-Phase2EscrowBitlocker function in $Mode mode" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
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


            # Create scheduled task for post-migration cleanup
            Write-EnhancedLog -Message "Creating scheduled task $TaskName at $TaskPath" -Level "INFO"

            # Define the parameters to be splatted
            $CreatePostMigrationCleanupTaskParams = @{
                TaskPath            = "AAD Migration"
                TaskName            = "Run Post migration cleanup"
                ScriptDirectory     = "C:\ProgramData\AADMigration\Scripts"
                ScriptName          = "ExecuteMigrationCleanupTasks.ps1"
                TaskArguments       = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"{ScriptPath}`""
                TaskPrincipalUserId = "NT AUTHORITY\SYSTEM"
                TaskRunLevel        = "Highest"
                PowerShellPath      = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                TaskDescription     = "Run post AAD Migration cleanup"
                TaskTriggerType     = "AtLogOn"  # Trigger type as a parameter
                Delay               = "PT1M"  # Optional delay before starting, set to 1 minute
            }

            # Call the function with the splatted parameters
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

            # Unblock user input and close form if in Prod mode
            if ($Mode -eq "Prod") {
                Write-EnhancedLog -Message "Unblocking user input and closing migration progress form" -Level "INFO"
                Block-UserInput -Block $false
            }
            else {
                Write-EnhancedLog -Message "Skipping unblocking of user input in Dev mode" -Level "WARNING"
            }

            # Optionally reboot the machine
            if ($RebootAfterCompletion -and $Mode -eq "Prod") {
                Write-EnhancedLog -Message "Rebooting computer after successful completion" -Level "INFO"
                Restart-Computer
            }
            else {
                Write-EnhancedLog -Message "Skipping reboot as per mode or user request" -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in PostRunOnce-Phase2EscrowBitlocker function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting PostRunOnce-Phase2EscrowBitlocker function" -Level "Notice"
    }
}
