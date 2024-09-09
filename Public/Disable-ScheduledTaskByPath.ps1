function Disable-ScheduledTaskByPath {
    <#
    .SYNOPSIS
    Disables a scheduled task by its name and path.

    .DESCRIPTION
    This function disables a scheduled task specified by its task name and path.

    .PARAMETER TaskName
    The name of the scheduled task.

    .PARAMETER TaskPath
    The path of the scheduled task.

    .EXAMPLE
    Disable-ScheduledTaskByPath -TaskName "TaskName" -TaskPath "\Folder\"

    This will disable the task "TaskName" in the folder "\Folder\" in Task Scheduler.

    .NOTES
    This function is useful for disabling tasks located in specific subfolders within the Task Scheduler.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the name of the scheduled task.")]
        [ValidateNotNullOrEmpty()]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true, HelpMessage = "Provide the path of the scheduled task.")]
        [ValidateNotNullOrEmpty()]
        [string]$TaskPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Disable-ScheduledTaskByPath function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Searching for scheduled task with Name: $TaskName and Path: $TaskPath" -Level "INFO"

            # Search for the scheduled task by TaskName and TaskPath
            $Task = Get-ScheduledTask | Where-Object { $_.TaskPath -eq $TaskPath -and $_.TaskName -eq $TaskName }

            if ($Task) {
                # Disable the found scheduled task
                Write-EnhancedLog -Message "Scheduled task found: '$($Task.TaskPath + $Task.TaskName)'. Disabling the task." -Level "INFO"
                Disable-ScheduledTask -TaskName ($Task.TaskPath + $Task.TaskName)
                Write-EnhancedLog -Message "Scheduled task '$($Task.TaskPath + $Task.TaskName)' has been successfully disabled." -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Scheduled task '$TaskPath$TaskName' not found." -Level "WARNING"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while disabling the scheduled task: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Disable-ScheduledTaskByPath function" -Level "NOTICE"
        }
    }

    End {
        Write-EnhancedLog -Message "Disable-ScheduledTaskByPath function completed" -Level "INFO"
    }
}
