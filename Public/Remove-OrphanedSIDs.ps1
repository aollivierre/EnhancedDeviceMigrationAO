
function Remove-OrphanedSIDs {
    <#
    .SYNOPSIS
    Removes orphaned SIDs from the specified group.

    .DESCRIPTION
    The Remove-OrphanedSIDs function checks for orphaned SIDs in a specified group, typically 'Administrators'. It attempts to remove any orphaned SIDs found and logs the process.

    .PARAMETER GroupName
    The name of the group from which orphaned SIDs should be removed. Defaults to "Administrators".

    .EXAMPLE
    Remove-OrphanedSIDs -GroupName "Administrators"
    Removes orphaned SIDs from the Administrators group.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Provide the group name to remove orphaned SIDs from.")]
        [string]$GroupName = "Administrators"
    )

    Begin {
        Write-EnhancedLog -Message "Starting Remove-OrphanedSIDs function" -Level "Notice"
        Write-EnhancedLog -Message "Checking for orphaned SIDs in the '$GroupName' group." -Level "INFO"

        # Get orphaned SIDs using the previous function
        $orphanedSIDs = Get-OrphanedSIDs -GroupName $GroupName

        # Check if any orphaned SIDs were found
        if ($orphanedSIDs.Count -eq 0) {
            Write-EnhancedLog -Message "No orphaned SIDs found in the '$GroupName' group." -Level "INFO"
        } else {
            Write-EnhancedLog -Message "Found $($orphanedSIDs.Count) orphaned SIDs in the '$GroupName' group." -Level "INFO"
        }
    }

    Process {
        # Proceed if orphaned SIDs were found
        if ($orphanedSIDs.Count -gt 0) {
            foreach ($orphanedSID in $orphanedSIDs) {
                try {
                    # Log the attempt to remove the SID
                    Write-EnhancedLog -Message "Attempting to remove orphaned SID: $($orphanedSID.AccountName) from '$GroupName'." -Level "INFO"

                    # Remove the orphaned SID from the group
                    Remove-LocalGroupMember -Group $GroupName -Member $orphanedSID.AccountName -ErrorAction Stop

                    # Log successful removal
                    Write-EnhancedLog -Message "Successfully removed orphaned SID: $($orphanedSID.AccountName)." -Level "INFO"
                } catch {
                    # Log any errors during removal
                    Write-EnhancedLog -Message "Failed to remove orphaned SID: $($orphanedSID.AccountName). Error: $($_.Exception.Message)" -Level "ERROR"
                    Handle-Error -ErrorRecord $_
                }
            }
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Remove-OrphanedSIDs function" -Level "Notice"
    }
}

# Example usage
# Remove-OrphanedSIDs -GroupName "Administrators"