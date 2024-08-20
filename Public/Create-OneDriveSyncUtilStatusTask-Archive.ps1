
# iex ((irm "https://raw.githubusercontent.com/aollivierre/module-starter/main/Module-Starter.ps1") -replace '\$Mode = "dev"', '$Mode = "dev"')

function Create-OneDriveSyncUtilStatusTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptDirectory,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskArguments,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskPrincipalUserId,
        
        [Parameter(Mandatory = $true)]
        [string]$PowerShellPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskRunLevel,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskDescription,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskTriggerType,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskRepetitionDuration,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskRepetitionInterval
    )

    Begin {
        Write-EnhancedLog -Message "Starting Create-OneDriveSyncUtilStatusTask function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Unregister the task if it exists
            Unregister-ScheduledTaskWithLogging -TaskName $TaskName

            $arguments = $TaskArguments.Replace("{ScriptPath}", "$ScriptDirectory\$ScriptName")

            $actionParams = @{
                Execute  = $PowerShellPath
                Argument = $arguments
            }
            $action = New-ScheduledTaskAction @actionParams

            # Create the scheduled task trigger based on the type provided
            $triggerParams = @{
                $TaskTriggerType = $true
            }
            $trigger = New-ScheduledTaskTrigger @triggerParams

            # Create the scheduled task principal
            $principalParams = @{
                UserId   = $TaskPrincipalUserId
                RunLevel = $TaskRunLevel
            }
            $principal = New-ScheduledTaskPrincipal @principalParams

            # Register the scheduled task
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
            Write-EnhancedLog -Message "An error occurred while creating the OneDrive sync status task: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Create-OneDriveSyncUtilStatusTask function" -Level "Notice"
    }
}

# Example usage with splatting
# $CreateOneDriveSyncStatusTaskParams = @{
#     TaskPath               = "AAD Migration"
#     TaskName               = "AADM Get OneDrive Sync Status"
#     ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
#     ScriptName             = "Check-OneDriveSyncStatus.ps1"
#     TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
#     TaskRepetitionDuration = "P1D"
#     TaskRepetitionInterval = "PT30M"
#     TaskTriggerType        = "AtLogOn"
#     TaskPrincipalUserId    = "BUILTIN\Users"
#     PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
#     TaskRunLevel           = "Highest"
#     TaskDescription        = "Get current OneDrive Sync Status and write to event log"
# }

# Create-OneDriveSyncUtilStatusTask @CreateOneDriveSyncStatusTaskParams
