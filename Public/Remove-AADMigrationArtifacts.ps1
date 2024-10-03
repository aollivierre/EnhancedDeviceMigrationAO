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
        Write-AADMigrationLog "Starting AAD migration artifact cleanup..."
    }

    Process {
        # Define paths to clean up
        $pathsToClean = @(
            @{ Path = "C:\logs"; Name = "Logs Path" },
            @{ Path = "C:\ProgramData\AADMigration"; Name = "AADMigration Path" },
            @{ Path = "C:\temp"; Name = "AADMigration Secrets Path" },
            @{ Path = "C:\temp-logs"; Name = "Temp Logs Path" }, # Added
            @{ Path = "C:\temp-git"; Name = "Temp Git Path" }, # Added
            @{ Path = "C:\temp-git\logs.zip"; Name = "Temp Zip File" }, # Added
            @{ Path = "C:\temp-git\syslog"; Name = "Syslog Repo Path" } # Added
        )

        # Loop through each path and perform the check and removal
        foreach ($item in $pathsToClean) {
            $path = $item.Path
            $name = $item.Name

            if (Test-Path -Path $path) {
                Write-AADMigrationLog "Removing $name ($path)..." -Level 'INFO'
                Remove-Item -Path $path -Recurse -Force
            }
            else {
                Write-AADMigrationLog "$name ($path) does not exist, skipping..." -Level 'WARNING'
            }
        }

        Write-AADMigrationLog "Path cleanup complete." -Level 'NOTICE'



        # Remove all scheduled tasks under the AAD Migration task path
        $scheduledTasks = Get-ScheduledTask -TaskPath '\AAD Migration\' -ErrorAction SilentlyContinue
        if ($scheduledTasks) {
            foreach ($task in $scheduledTasks) {
                Write-AADMigrationLog "Removing scheduled task: $($task.TaskName)..." -Level 'INFO'
                Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false
            }
        }
        else {
            Write-AADMigrationLog "No scheduled tasks found under \AAD Migration, skipping..." -Level 'WARNING'
        }

        # Remove the scheduled task folder named AAD Migration
        try {
            $taskFolder = New-Object -ComObject "Schedule.Service"
            $taskFolder.Connect()
            $rootFolder = $taskFolder.GetFolder("\")
            $aadMigrationFolder = $rootFolder.GetFolder("AAD Migration")
            $aadMigrationFolder.DeleteFolder("", 0)
            Write-AADMigrationLog "Scheduled task folder AAD Migration removed successfully." -Level 'INFO'
        }
        catch {
            Write-AADMigrationLog "Scheduled task folder AAD Migration does not exist or could not be removed." -Level 'ERROR'
        }

        # Remove the local user called MigrationInProgress
        $localUser = "MigrationInProgress"
        try {
            $user = Get-LocalUser -Name $localUser -ErrorAction Stop
            if ($user) {
                Write-AADMigrationLog "Removing local user $localUser..." -Level 'INFO'
                Remove-LocalUser -Name $localUser -Force
            }
        }
        catch {
            Write-AADMigrationLog "Local user $localUser does not exist, skipping..." -Level 'WARNING'
        }
    }

    End {
        Write-AADMigrationLog "AAD migration artifact cleanup completed." -Level 'INFO'
    }
}

# Remove-AADMigrationArtifacts