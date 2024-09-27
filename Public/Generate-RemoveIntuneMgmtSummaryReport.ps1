

# Function to generate a summary report
function Generate-RemoveIntuneMgmtSummaryReport {
    param (
        [int]$successCount,
        [int]$warningCount,
        [int]$errorCount,
        [System.Collections.Generic.List[PSCustomObject]]$summaryTable
    )

    # Final Summary Report
    Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"
    Write-EnhancedLog -Message "Final Intune Management Cleanup Summary Report" -Level "NOTICE"
    Write-EnhancedLog -Message "Total operations processed: $($successCount + $warningCount + $errorCount)" -Level "INFO"
    Write-EnhancedLog -Message "Successfully completed: $successCount" -Level "INFO"
    Write-EnhancedLog -Message "Warnings: $warningCount" -Level "WARNING"
    Write-EnhancedLog -Message "Errors: $errorCount" -Level "ERROR"
    Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"

    # Color-coded summary for the console
    Write-Host "----------------------------------------" -ForegroundColor White
    Write-Host "Final Intune Management Cleanup Summary Report" -ForegroundColor Cyan
    Write-Host "Total operations processed: $($successCount + $warningCount + $errorCount)" -ForegroundColor White
    Write-Host "Successfully completed: $successCount" -ForegroundColor Green
    Write-Host "Warnings: $warningCount" -ForegroundColor Yellow
    Write-Host "Errors: $errorCount" -ForegroundColor Red
    Write-Host "----------------------------------------" -ForegroundColor White

    # Display the summary table of actions and their final states
    Write-Host "Intune Management Cleanup Summary:" -ForegroundColor Cyan
    $summaryTable | Format-Table -AutoSize

    # Optionally log the summary to the enhanced log as well
    foreach ($row in $summaryTable) {
        Write-EnhancedLog -Message "Action: $($row.Action), Path: $($row.Path), Status: $($row.Status)" -Level "INFO"
    }
}