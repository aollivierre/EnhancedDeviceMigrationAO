# function Create-UserFileBackupTask {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$TaskPath,
#         [Parameter(Mandatory = $true)]
#         [string]$TaskName,
#         [Parameter(Mandatory = $true)]
#         [string]$ScriptDirectory,
#         [Parameter(Mandatory = $true)]
#         [string]$ScriptName,
#         [Parameter(Mandatory = $true)]
#         [string]$TaskArguments,
#         [Parameter(Mandatory = $true)]
#         [string]$TaskRepetitionDuration,
#         [Parameter(Mandatory = $true)]
#         [string]$TaskRepetitionInterval,
#         [Parameter(Mandatory = $true)]
#         [string]$TaskPrincipalGroupId,
#         [Parameter(Mandatory = $true)]
#         [string]$PowerShellPath,
#         [Parameter(Mandatory = $true)]
#         [string]$TaskDescription,
#         [Parameter(Mandatory = $true)]
#         [switch]$AtLogOn

#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Create-UserFileBackupTask function" -Level "Notice"
#         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
#     }

#     Process {
#         try {
#             # Unregister the task if it exists
#             Unregister-ScheduledTaskWithLogging -TaskName $TaskName

#             $arguments = $TaskArguments.Replace("{ScriptPath}", "$ScriptDirectory\$ScriptName")

#             $actionParams = @{
#                 Execute  = $PowerShellPath
#                 Argument = $arguments
#             }
#             $action = New-ScheduledTaskAction @actionParams

#             $triggerParams = @{
#                 AtLogOn = $AtLogOn
#             }
            
#             $trigger = New-ScheduledTaskTrigger @triggerParams

#             $principalParams = @{
#                 GroupId = $TaskPrincipalGroupId
#             }
#             $principal = New-ScheduledTaskPrincipal @principalParams

#             $registerTaskParams = @{
#                 Principal   = $principal
#                 Action      = $action
#                 Trigger     = $trigger
#                 TaskName    = $TaskName
#                 Description = $TaskDescription
#                 TaskPath    = $TaskPath
#             }
#             $Task = Register-ScheduledTask @registerTaskParams

#             $Task.Triggers.Repetition.Duration = $TaskRepetitionDuration
#             $Task.Triggers.Repetition.Interval = $TaskRepetitionInterval
#             $Task | Set-ScheduledTask
#         }
#         catch {
#             Write-EnhancedLog -Message "An error occurred while creating the OneDrive sync status task: $($_.Exception.Message)" -Level "ERROR"
#             Handle-Error -ErrorRecord $_
#         }
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Create-UserFileBackupTask function" -Level "Notice"
#     }
# }


function Create-UserFileBackupTask {
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
        [string]$TaskRepetitionDuration,
        [Parameter(Mandatory = $true)]
        [string]$TaskRepetitionInterval,
        [Parameter(Mandatory = $false)]
        [string]$TaskPrincipalGroupId,  # Optional now
        [Parameter(Mandatory = $true)]
        [string]$PowerShellPath,
        [Parameter(Mandatory = $true)]
        [string]$TaskDescription,
        [Parameter(Mandatory = $true)]
        [switch]$AtLogOn,
        [Parameter(Mandatory = $false)]
        [switch]$UseCurrentUser  # Switch to use the current user
    )

    Begin {
        Write-EnhancedLog -Message "Starting Create-UserFileBackupTask function" -Level "Notice"
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

            $triggerParams = @{
                AtLogOn = $AtLogOn
            }
            
            $trigger = New-ScheduledTaskTrigger @triggerParams

            # Determine whether to use GroupId or Current Logged-in User
            if ($UseCurrentUser) {
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $principalParams = @{
                    UserId = $currentUser
                }
                Write-EnhancedLog -Message "Using current logged-in user: $currentUser" -Level "INFO"
            }
            else {
                $principalParams = @{
                    GroupId = $TaskPrincipalGroupId
                }
                Write-EnhancedLog -Message "Using group ID: $TaskPrincipalGroupId" -Level "INFO"
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

            $Task.Triggers.Repetition.Duration = $TaskRepetitionDuration
            $Task.Triggers.Repetition.Interval = $TaskRepetitionInterval
            $Task | Set-ScheduledTask
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while creating the User File Backup task: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Create-UserFileBackupTask function" -Level "Notice"
    }
}




# # # # Example usage with splatting
# $CreateUserFileBackupTaskParams = @{
#     TaskPath               = "AAD Migration"
#     TaskName               = "Backup User Files"
#     ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
#     ScriptName             = "BackupUserFiles.ps1"
#     TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
#     TaskRepetitionDuration = "P1D"
#     TaskRepetitionInterval = "PT30M"
#     TaskPrincipalGroupId   = "BUILTIN\Users"
#     PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
#     TaskDescription        = "Backup User Files to OneDrive"
#     AtLogOn                = $true
# }

# Create-UserFileBackupTask @CreateUserFileBackupTaskParams