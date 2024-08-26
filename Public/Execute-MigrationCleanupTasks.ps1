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
    }
    Execute-MigrationCleanupTasks @params
    Executes the post-run operations.
    #>
  
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TempUser,
  
        [Parameter(Mandatory = $true)]
        [hashtable]$RegistrySettings,
  
        [Parameter(Mandatory = $true)]
        [string[]]$MigrationDirectories
    )
  
    Begin {
        Write-EnhancedLog -Message "Starting Execute-MigrationCleanupTasks function" -Level "Notice"
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
  
            # Disable local user accounts
            Write-EnhancedLog -Message "Disabling local user accounts" -Level "INFO"
            Disable-LocalUserAccounts
            Write-EnhancedLog -Message "Local user accounts disabled" -Level "INFO"
  
            # Set registry values
            Write-EnhancedLog -Message "Applying registry settings" -Level "INFO"
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
  
            # Remove scheduled tasks
            Write-EnhancedLog -Message "Removing scheduled tasks in TaskPath: AAD Migration" -Level "INFO"
            $taskParams = @{
                TaskPath = "AAD Migration"
            }
            Remove-ScheduledTasks @taskParams
            Write-EnhancedLog -Message "Scheduled tasks removed from TaskPath: AAD Migration" -Level "INFO"
  
            # Remove migration files
            Write-EnhancedLog -Message "Removing migration directories: $MigrationDirectories" -Level "INFO"
            $removeFilesParams = @{
                Directories = $MigrationDirectories
            }
            Remove-MigrationFiles @removeFilesParams
            Write-EnhancedLog -Message "Migration directories removed: $MigrationDirectories" -Level "INFO"
  
            # Clear OneDrive cache
            Write-EnhancedLog -Message "Clearing OneDrive cache" -Level "INFO"
            Clear-OneDriveCache
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
  