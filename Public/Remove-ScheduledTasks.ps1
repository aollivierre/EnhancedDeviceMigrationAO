
# Function to remove scheduled tasks
function Remove-ScheduledTasks {
    param (
        [string]$TaskPathBase,
        [string]$Account
    )

    Write-EnhancedLog -Message "Attempting to remove scheduled tasks at path $TaskPathBase\$Account" -Level "INFO"
    Get-ScheduledTask -TaskPath "$TaskPathBase\$Account\*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    Write-EnhancedLog -Message "Scheduled tasks removed successfully (if any existed)" -Level "INFO"

    return [PSCustomObject]@{
        Action = "Remove Scheduled Tasks"
        Path   = "$TaskPathBase\$Account"
        Status = "Success"
    }
}