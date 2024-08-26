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
            
            .NOTES
                This function is useful for disabling tasks located in specific subfolders within the Task Scheduler.
            #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
            
        [Parameter(Mandatory = $true)]
        [string]$TaskPath
    )
            
    Begin {
        Write-EnhancedLog -Message "Starting Disable-ScheduledTaskByPath function" -Level "NOTICE"
    }
            
    Process {
        $Task = Get-ScheduledTask | Where-Object { $_.TaskPath -eq $TaskPath -and $_.TaskName -eq $TaskName }
                    
        if ($Task) {
            Disable-ScheduledTask -TaskName ($Task.TaskPath + $Task.TaskName)
            Write-Host "Scheduled task '$($Task.TaskPath + $Task.TaskName)' has been disabled."
        }
        else {
            Write-Host "Scheduled task '$TaskPath$TaskName' not found."
        }
    }
            
    End {
        Write-EnhancedLog -Message "Exiting Disable-ScheduledTaskByPath function" -Level "NOTICE"
    }
}
