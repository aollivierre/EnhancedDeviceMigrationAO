function Execute-MigrationCleanupTasks {
    <#
    .SYNOPSIS
    Executes post-run operations for the third phase of the migration process.
  
    .DESCRIPTION
    The Execute-MigrationCleanupTasks function performs cleanup tasks after migration, including removing temporary user accounts, disabling local user accounts, removing scheduled tasks, clearing OneDrive cache, and setting registry values.
  
    .PARAMETER TempUser
    The name of the temporary user account to be removed.
  
    .PARAMETER RegistrySettings
    A hashtable of registry settings to be applied.
  
    .PARAMETER MigrationDirectories
    An array of directories to be removed as part of migration cleanup.

    .PARAMETER Mode
    Specifies the mode in which the script should run. Options are "Dev" for development mode or "Prod" for production mode. This determines whether the `Disable-LocalUserAccounts` function will skip certain accounts.
  
    .EXAMPLE
    $params = @{
        TempUser = "TempUser"
        RegistrySettings = @{
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" = @{
                "dontdisplaylastusername" = @{
                    "Type" = "DWORD"
                    "Data" = "0"
                }
                "legalnoticecaption" = @{
                    "Type" = "String"
                    "Data" = $null
                }
                "legalnoticetext" = @{
                    "Type" = "String"
                    "Data" = $null
                }
            }
            "HKLM:\Software\Policies\Microsoft\Windows\Personalization" = @{
                "NoLockScreen" = @{
                    "Type" = "DWORD"
                    "Data" = "0"
                }
            }
        }
        MigrationDirectories = @(
            "C:\ProgramData\AADMigration\Files",
            "C:\ProgramData\AADMigration\Scripts",
            "C:\ProgramData\AADMigration\Toolkit"
        )
        Mode = "Dev"
    }
    Execute-MigrationCleanupTasks @params
    Executes the post-run operations in Dev mode.
    #>
  
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TempUser,
  
        [Parameter(Mandatory = $true)]
        [hashtable]$RegistrySettings,
  
        [Parameter(Mandatory = $true)]
        [string[]]$MigrationDirectories,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Dev", "Prod")]
        [string]$Mode
    )
  
    Begin {
        Write-EnhancedLog -Message "Starting Execute-MigrationCleanupTasks function in $Mode mode" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }
  
    Process {
        try {
            # Remove temporary user account
            Write-EnhancedLog -Message "Removing temporary user account: $TempUser" -Level "INFO"
            $removeUserParams = @{
                UserName = $TempUser
            }
            Remove-LocalUserAccount @removeUserParams
            Write-EnhancedLog -Message "Temporary user account $TempUser removed" -Level "INFO"
  
            Manage-LocalUserAccounts -Mode $Mode
  
            # Set registry values
            Write-EnhancedLog -Message "Applying registry settings" -Level "INFO"
            foreach ($regPath in $RegistrySettings.Keys) {
                foreach ($regName in $RegistrySettings[$regPath].Keys) {
                    $regSetting = $RegistrySettings[$regPath][$regName]

                    if ($null -ne $regSetting["Data"]) {
                        Write-EnhancedLog -Message "Setting registry value $regName at $regPath" -Level "INFO"
                    
                        $regParams = @{
                            RegKeyPath = $regPath
                            RegValName = $regName
                            RegValType = $regSetting["Type"]
                            RegValData = $regSetting["Data"]
                        }
                    
                        # If the data is an empty string, explicitly set it as such
                        if ($regSetting["Data"] -eq "") {
                            $regParams.RegValData = ""
                        }
                    
                        Set-RegistryValue @regParams
                        Write-EnhancedLog -Message "Registry value $regName at $regPath set" -Level "INFO"
                    }
                    else {
                        Write-EnhancedLog -Message "Skipping registry value $regName at $regPath due to null data" -Level "WARNING"
                    }
                    
                }
            }
  
            # Remove scheduled tasks
            Write-EnhancedLog -Message "Removing scheduled tasks in TaskPath: AAD Migration" -Level "INFO"

            # Retrieve all tasks in the "AAD Migration" path
            $tasks = Get-ScheduledTask -TaskPath "\AAD Migration\" -ErrorAction SilentlyContinue

            # Loop through each task and unregister it using the Unregister-ScheduledTaskWithLogging function
            foreach ($task in $tasks) {
                Unregister-ScheduledTaskWithLogging -TaskName $task.TaskName
            }

            Write-EnhancedLog -Message "Scheduled tasks removed from TaskPath: AAD Migration" -Level "INFO"
  
        
  
            # Clear OneDrive cache
            Write-EnhancedLog -Message "Clearing OneDrive cache" -Level "INFO"
            # Clear-OneDriveCache

            $CreateOneDriveCacheClearTaskParams = @{
                TaskPath               = "AAD Migration"
                TaskName               = "Clear OneDrive Cache"
                ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
                ScriptName             = "ClearOneDriveCache.Task.ps1"
                TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
                TaskRepetitionDuration = "P1D"
                TaskRepetitionInterval = "PT30M"
                TaskPrincipalGroupId   = "BUILTIN\Users"
                PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                TaskDescription        = "Clears the OneDrive cache by restarting the OneDrive process"
                AtLogOn                = $true
            }

            Create-OneDriveCacheClearTask @CreateOneDriveCacheClearTaskParams


            $taskParams = @{
                TaskPath = "\AAD Migration"
                TaskName = "Clear OneDrive Cache"
            }

            # Trigger OneDrive Sync Status Scheduled Task
            Trigger-ScheduledTask @taskParams


            # Remove migration files
            Write-EnhancedLog -Message "Removing migration directories: $MigrationDirectories" -Level "INFO"
            $removeFilesParams = @{
                Directories = $MigrationDirectories
            }
            Remove-MigrationFiles @removeFilesParams
            Write-EnhancedLog -Message "Migration directories removed: $MigrationDirectories" -Level "INFO"


            Write-EnhancedLog -Message "OneDrive cache cleared" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Execute-MigrationCleanupTasks function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }
  
    End {
        Write-EnhancedLog -Message "Exiting Execute-MigrationCleanupTasks function" -Level "Notice"
    }
}
