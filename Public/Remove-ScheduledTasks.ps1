function Remove-ScheduledTasks {
    <#
    .SYNOPSIS
    Removes scheduled tasks created for the migration.
  
    .DESCRIPTION
    The Remove-ScheduledTasks function removes all scheduled tasks under a specified task path.
  
    .PARAMETER TaskPath
    The path of the task in Task Scheduler.
  
    .EXAMPLE
    $params = @{
        TaskPath = "AAD Migration"
    }
    Remove-ScheduledTasks @params
    Removes all scheduled tasks under the "AAD Migration" task path.
    #>
  
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskPath
    )
  
    Begin {
        Write-EnhancedLog -Message "Starting Remove-ScheduledTasks function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }
  
    Process {
        try {
            Write-EnhancedLog -Message "Removing scheduled tasks under task path: $TaskPath" -Level "INFO"
            $tasks = Get-ScheduledTask -TaskPath "\$TaskPath\"
            foreach ($task in $tasks) {
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction Stop
                Write-EnhancedLog -Message "Successfully removed scheduled task: $($task.TaskName)" -Level "INFO"
            }
            $scheduler = New-Object -ComObject "Schedule.Service"
            $scheduler.Connect()
            $rootFolder = $scheduler.GetFolder("\")
            $rootFolder.DeleteFolder($TaskPath, $null)
            Write-EnhancedLog -Message "Successfully removed task folder: $TaskPath" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Remove-ScheduledTasks function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }
  
    End {
        Write-EnhancedLog -Message "Exiting Remove-ScheduledTasks function" -Level "Notice"
    }
  }
  
  # # Example usage
  # $params = @{
  #   TaskPath = "AAD Migration"
  # }
  # Remove-ScheduledTasks @params