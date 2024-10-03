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
        $RegistrySettings,
  
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
            # Write-EnhancedLog -Message "Applying registry settings" -Level "INFO"
            # foreach ($regPath in $RegistrySettings.Keys) {
            #     foreach ($regName in $RegistrySettings[$regPath].Keys) {
            #         $regSetting = $RegistrySettings[$regPath][$regName]

            #         if ($null -ne $regSetting["Data"]) {
            #             Write-EnhancedLog -Message "Setting registry value $regName at $regPath" -Level "INFO"
                    
            #             $regParams = @{
            #                 RegKeyPath = $regPath
            #                 RegValName = $regName
            #                 RegValType = $regSetting["Type"]
            #                 RegValData = $regSetting["Data"]
            #             }
                    
            #             # If the data is an empty string, explicitly set it as such
            #             if ($regSetting["Data"] -eq "") {
            #                 $regParams.RegValData = ""
            #             }
                    
            #             Set-RegistryValue @regParams
            #             Write-EnhancedLog -Message "Registry value $regName at $regPath set" -Level "INFO"
            #         }
            #         else {
            #             Write-EnhancedLog -Message "Skipping registry value $regName at $regPath due to null data" -Level "WARNING"
            #         }
                    
            #     }
            # }


            # Apply the registry settings using the defined hash table
            # Apply-RegistrySettings -RegistrySettings $RegistrySettings

            # Iterate through each registry setting
            # foreach ($regSetting in $RegistrySettings) {
            #     $regKeyPath = $regSetting.RegKeyPath
    
            #     # Apply the registry setting
            #     Apply-RegistrySettings -RegistrySettings @($regSetting) -RegKeyPath $regKeyPath
            # }
            



            # Create a new hashtable to store settings grouped by their RegKeyPath
            $groupedSettings = @{}

            # Group the registry settings by their RegKeyPath
            foreach ($regSetting in $RegistrySettings) {
                $regKeyPath = $regSetting.RegKeyPath
     
                if (-not $groupedSettings.ContainsKey($regKeyPath)) {
                    $groupedSettings[$regKeyPath] = @()
                }
     
                # Add the current setting to the appropriate group
                $groupedSettings[$regKeyPath] += $regSetting
            }
     
            # Now apply the grouped registry settings
            foreach ($regKeyPath in $groupedSettings.Keys) {
                $settingsForKey = $groupedSettings[$regKeyPath]
     
                # Call Apply-RegistrySettings once per group with the correct RegKeyPath
                Apply-RegistrySettings -RegistrySettings $settingsForKey -RegKeyPath $regKeyPath
            }



            # #Region Set registry values

            # # Initialize counters and summary table
            # $infoCount = 0
            # $warningCount = 0
            # $errorCount = 0
            # # Initialize the summary table using a .NET List for better performance
            # $summaryTable = [System.Collections.Generic.List[PSCustomObject]]::new()

            # # Set registry values
            # Write-EnhancedLog -Message "Applying registry settings" -Level "INFO"
            # foreach ($regPath in $RegistrySettings.Keys) {
            #     foreach ($regName in $RegistrySettings[$regPath].Keys) {
            #         $regSetting = $RegistrySettings[$regPath][$regName]

            #         $summaryRow = [PSCustomObject]@{
            #             RegistryPath  = $regPath
            #             RegistryName  = $regName
            #             RegistryValue = if ($null -ne $regSetting["Data"]) { $regSetting["Data"] } else { "null" }
            #             Status        = ""
            #         }

            #         if ($null -ne $regSetting["Data"]) {
            #             Write-EnhancedLog -Message "Setting registry value $regName at $regPath" -Level "INFO"
            #             $infoCount++

            #             $regParams = @{
            #                 RegKeyPath = $regPath
            #                 RegValName = $regName
            #                 RegValType = $regSetting["Type"]
            #                 RegValData = $regSetting["Data"]
            #             }

            #             # If the data is an empty string, explicitly set it as such
            #             if ($regSetting["Data"] -eq "") {
            #                 $regParams.RegValData = ""
            #             }

            #             try {
            #                 # Set-RegistryValue @regParams

            #                 # Call the Set-RegistryValue function and capture the result
            #                 $setRegistryResult = Set-RegistryValue @regParams

            #                 # Build decision-making logic based on the result
            #                 if ($setRegistryResult -eq $true) {
            #                     Write-EnhancedLog -Message "Successfully set the registry value: $regValName at $regKeyPath" -Level "INFO"
            #                     $summaryRow.Status = "Success"
            #                 }
            #                 else {
            #                     Write-EnhancedLog -Message "Failed to set the registry value: $regValName at $regKeyPath" -Level "ERROR"
            #                     $summaryRow.Status = "Failed"
            #                 }

            #                 Write-EnhancedLog -Message "Registry value $regName at $regPath set" -Level "INFO"
                            
            #             }
            #             catch {
            #                 Write-EnhancedLog -Message "Error setting registry value $regName at $regPath $($_.Exception.Message)" -Level "ERROR"
            #                 $errorCount++
            #                 $summaryRow.Status = "Failed"
            #             }
            #         }
            #         else {
            #             Write-EnhancedLog -Message "Skipping registry value $regName at $regPath due to null data" -Level "WARNING"
            #             $warningCount++
            #             $summaryRow.Status = "Skipped"
            #         }

            #         $summaryTable.Add($summaryRow)
            #     }
            # }

            # # Final Summary Report
            # Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"
            # Write-EnhancedLog -Message "Final Summary Report" -Level "NOTICE"
            # Write-EnhancedLog -Message "Total registry settings processed: $($infoCount + $warningCount + $errorCount)" -Level "INFO"
            # Write-EnhancedLog -Message "Successfully applied registry settings: $infoCount" -Level "INFO"
            # Write-EnhancedLog -Message "Skipped registry settings (due to null data): $warningCount" -Level "WARNING"
            # Write-EnhancedLog -Message "Failed registry settings: $errorCount" -Level "ERROR"
            # Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"

            # # Color-coded summary for the console
            # Write-Host "----------------------------------------" -ForegroundColor White
            # Write-Host "Final Summary Report" -ForegroundColor Cyan
            # Write-Host "Total registry settings processed: $($infoCount + $warningCount + $errorCount)" -ForegroundColor White
            # Write-Host "Successfully applied registry settings: $infoCount" -ForegroundColor Green
            # Write-Host "Skipped registry settings (due to null data): $warningCount" -ForegroundColor Yellow
            # Write-Host "Failed registry settings: $errorCount" -ForegroundColor Red
            # Write-Host "----------------------------------------" -ForegroundColor White

            # # Display the summary table of registry keys and their final states
            # Write-Host "Registry Settings Summary:" -ForegroundColor Cyan
            # $summaryTable | Format-Table -AutoSize

            # # Optionally log the summary to the enhanced log as well
            # foreach ($row in $summaryTable) {
            #     Write-EnhancedLog -Message "RegistryPath: $($row.RegistryPath), RegistryName: $($row.RegistryName), Value: $($row.RegistryValue), Status: $($row.Status)" -Level "INFO"
            # }


            # #endRegion Set registry values
  


            
  
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
                TaskPath = "AAD Migration"
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
            throw $_
        }
    }
  
    End {
        Write-EnhancedLog -Message "Exiting Execute-MigrationCleanupTasks function" -Level "Notice"
    }
}
