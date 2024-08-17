function Create-UserFileBackupTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        [Parameter(Mandatory = $true)]
        [string]$BackupScriptPath,
        [Parameter(Mandatory = $true)]
        [string]$TaskRepetitionDuration,
        [Parameter(Mandatory = $true)]
        [string]$TaskRepetitionInterval,
        [Parameter(Mandatory = $true)]
        [string]$TaskPrincipalGroupId,
        [Parameter(Mandatory = $true)]
        [string]$PowerShellPath,
        [Parameter(Mandatory = $true)]
        [string]$TaskDescription
    )

    Begin {
        Write-EnhancedLog -Message "Starting Create-UserFileBackupTask function" -Level "Notice"
        Log-Params -Params @{
            TaskPath               = $TaskPath
            TaskName               = $TaskName
            BackupScriptPath       = $BackupScriptPath
            TaskRepetitionDuration = $TaskRepetitionDuration
            TaskRepetitionInterval = $TaskRepetitionInterval
            TaskPrincipalGroupId   = $TaskPrincipalGroupId
            PowerShellPath         = $PowerShellPath
            TaskDescription        = $TaskDescription
        }
    }

    Process {
        try {
            $arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$BackupScriptPath`""

            $actionParams = @{
                Execute = $PowerShellPath
                Argument = $arguments
            }
            $action = New-ScheduledTaskAction @actionParams

            $triggerParams = @{
                AtLogOn = $true
            }
            $trigger = New-ScheduledTaskTrigger @triggerParams

            $principalParams = @{
                GroupId = $TaskPrincipalGroupId
            }
            $principal = New-ScheduledTaskPrincipal @principalParams

            $registerTaskParams = @{
                Principal   = $principal
                Action      = $action
                Trigger     = $trigger
                TaskName    = $TaskName
                Description = $TaskDescription
                TaskPath    = $TaskPath
            }
            $Task = Register-ScheduledTask @registerTaskParams

            # Set repetition properties
            $Task.Triggers.Repetition.Duration = $TaskRepetitionDuration
            $Task.Triggers.Repetition.Interval = $TaskRepetitionInterval
            $Task | Set-ScheduledTask
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while creating the user file backup task: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Create-UserFileBackupTask function" -Level "Notice"
    }
}

# # Example usage with splatting
# $CreateUserFileBackupTaskParams = @{
#     TaskPath                = "Backup Tasks"
#     TaskName                = "User File Backup"
#     BackupScriptPath        = "C:\Scripts\BackupUserFiles.ps1"
#     TaskRepetitionDuration  = "P1D"  # 1 day
#     TaskRepetitionInterval  = "PT1H"  # 1 hour
#     TaskPrincipalGroupId    = "BUILTIN\Administrators"
#     PowerShellPath          = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
#     TaskDescription         = "Backup user files to a designated location"
# }

# Create-UserFileBackupTask @CreateUserFileBackupTaskParams
