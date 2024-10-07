function Remove-AADMigrationArtifacts {
    <#
    .SYNOPSIS
    Cleans up AAD migration artifacts, including directories, scheduled tasks, and a local user.

    .DESCRIPTION
    The `Remove-AADMigrationArtifacts` function removes the following AAD migration-related artifacts:
    - The `C:\logs` directory
    - The `C:\ProgramData\AADMigration` directory
    - All scheduled tasks under the `AAD Migration` task path
    - The `AAD Migration` scheduled task folder
    - A local user account named `MigrationInProgress`

    .EXAMPLE
    Remove-AADMigrationArtifacts

    Cleans up all AAD migration artifacts.

    .NOTES
    This function should be run with administrative privileges.
    #>

    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting AAD migration artifact cleanup..."

        $global:JobName = "AAD_Migration"
        try {
            # $tempPath = Get-ReliableTempPath -LogLevel "INFO"
            $tempPath = 'c:\temp'
            Write-EnhancedLog -Message "Temp Path Set To: $tempPath"
        }
        catch {
            Write-EnhancedLog -Message "Failed to get a valid temp path: $_"
        }
    }

    Process {
        # Define paths to clean up
        $pathsToClean = @(
            @{ Path = "C:\logs"; Name = "Logs Path" },
            @{ Path = "C:\ProgramData\AADMigration"; Name = "$global:JobName Path" },
            @{ Path = "$tempPath\$global:JobName-secrets"; Name = "$global:JobName Secrets Path" },
            @{ Path = "$tempPath\$global:JobName-logs"; Name = "$global:JobName Temp Logs Path" }, # Added
            @{ Path = "$tempPath\$global:JobName-git"; Name = "$global:JobName Temp Git Path" }, # Added
            @{ Path = "$tempPath\$global:JobName-git\logs.zip"; Name = "$global:JobName Temp Zip File" }, # Added
            @{ Path = "$tempPath\$global:JobName-git\syslog"; Name = "$global:JobName Syslog Repo Path" } # Added
        )

        # Loop through each path and perform the check and removal
        foreach ($item in $pathsToClean) {
            $path = $item.Path
            $name = $item.Name

            if (Test-Path -Path $path) {
                Write-EnhancedLog -Message "Removing $name ($path)..." -Level 'INFO'
                Remove-Item -Path $path -Recurse -Force

                # Remove-EnhancedItem -Path $path -MaxRetries 3 -RetryInterval 3

            }
            else {
                Write-EnhancedLog -Message "$name ($path) does not exist, skipping..." -Level 'WARNING'
            }
        }

        Write-EnhancedLog -Message "Path cleanup complete." -Level 'NOTICE'



        # Remove all scheduled tasks under the AAD Migration task path
        $scheduledTasks = Get-ScheduledTask -TaskPath '\AAD Migration\' -ErrorAction SilentlyContinue
        if ($scheduledTasks) {
            foreach ($task in $scheduledTasks) {
                Write-EnhancedLog -Message "Removing scheduled task: $($task.TaskName)..." -Level 'INFO'
                Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false
            }
        }
        else {
            Write-EnhancedLog -Message "No scheduled tasks found under \AAD Migration, skipping..." -Level 'WARNING'
        }

        # Remove the scheduled task folder named AAD Migration
        try {
            $taskFolder = New-Object -ComObject "Schedule.Service"
            $taskFolder.Connect()
            $rootFolder = $taskFolder.GetFolder("\")
            $aadMigrationFolder = $rootFolder.GetFolder("AAD Migration")
            $aadMigrationFolder.DeleteFolder("", 0)
            Write-EnhancedLog -Message "Scheduled task folder AAD Migration removed successfully." -Level 'INFO'
        }
        catch {
            Write-EnhancedLog -Message "Scheduled task folder AAD Migration does not exist or could not be removed." -Level 'ERROR'
        }

        # Remove the local user called MigrationInProgress
        $localUser = "MigrationInProgress"
        try {
            $user = Get-LocalUser -Name $localUser -ErrorAction Stop
            if ($user) {
                Write-EnhancedLog -Message "Removing local user $localUser..." -Level 'INFO'
                Remove-LocalUser -Name $localUser -Force
            }
        }
        catch {
            Write-EnhancedLog -Message "Local user $localUser does not exist, skipping..." -Level 'WARNING'
        }


        $RegistrySettings = @(
            @{
                RegValName = "dontdisplaylastusername"
                RegValType = "DWORD"
                RegValData = "0"
                RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            },
            @{
                RegValName = "legalnoticecaption"
                RegValType = "String"
                RegValData = ""
                RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            },
            @{
                RegValName = "legalnoticetext"
                RegValType = "String"
                RegValData = ""
                RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            },
            @{
                RegValName = "NoLockScreen"
                RegValType = "DWORD"
                RegValData = "0"
                RegKeyPath = "HKLM:\Software\Policies\Microsoft\Windows\Personalization"
            }
        )






        
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






        # Wait-Debugger



    }

    End {
        Write-EnhancedLog -Message "AAD migration artifact cleanup completed." -Level 'INFO'
    }
}

# Remove-AADMigrationArtifacts