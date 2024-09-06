function Get-OrphanedSIDs {
    <#
    .SYNOPSIS
    Identifies orphaned SIDs in the 'Administrators' group.

    .DESCRIPTION
    The Get-OrphanedSIDs function retrieves members of the 'Administrators' group and checks if each member resolves to a valid user or group. Orphaned SIDs are identified when the account cannot be resolved, and those SIDs are returned as the output.

    .EXAMPLE
    $orphanedSIDs = Get-OrphanedSIDs
    Outputs a list of orphaned SIDs from the 'Administrators' group.
    #>

    [CmdletBinding()]
    param (
        [string]$GroupName = "Administrators"
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-OrphanedSIDs function" -Level "Notice"
        
        # Initialize a list for storing orphaned SIDs efficiently
        $orphanedSIDs = [System.Collections.Generic.List[PSCustomObject]]::new()

        Write-EnhancedLog -Message "Retrieving members of the '$GroupName' group." -Level "INFO"
    }

    Process {
        # Use WMI to retrieve members of the specified group
        # Use single quotes for the string and concatenate $GroupName
  
        try {
            # Log the start of the retrieval process
            Write-EnhancedLog -Message "Attempting to retrieve members of the '$GroupName' group." -Level "INFO"

            $groupPattern = [regex]::Escape($GroupName)
            $admins = Get-WmiObject -Class Win32_GroupUser | Where-Object { $_.GroupComponent -match $groupPattern }
        
            # Log the count of members found
            $count = $admins.Count
            Write-EnhancedLog -Message "Found $count members in the '$GroupName' group." -Level "INFO"
        
            if ($count -gt 0) {
                # Log details of each group member
                Write-EnhancedLog -Message "Listing all members of the '$GroupName' group:" -Level "INFO"
                foreach ($admin in $admins) {
                    # Extract the username from the PartComponent property
                    if ($admin.PartComponent -match 'Win32_UserAccount.Domain="[^"]+",Name="([^"]+)"') {
                        $accountName = $matches[1]
                        
                        # Log the extracted account name
                        Write-EnhancedLog -Message "Member: $accountName" -Level "INFO"
                    }
                    else {
                        # Log a message if the PartComponent does not match the expected pattern
                        Write-EnhancedLog -Message "Could not extract a valid account name from: $($admin.PartComponent)" -Level "WARNING"
                    }
                }
                
            }
            else {
                Write-EnhancedLog -Message "No members found in the '$GroupName' group." -Level "WARNING"
            }
        }
        catch {
            # Log the error if retrieval fails
            Write-EnhancedLog -Message "Failed to retrieve members of the '$GroupName' group: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        
            # Re-throw the exception to handle it further upstream if needed
            throw
        }

        # Iterate over each group member
        foreach ($admin in $admins) {
            # Extract the account name from the PartComponent
            if ($admin.PartComponent -match 'Win32_UserAccount.Domain="[^"]+",Name="([^"]+)"') {
                $accountName = $matches[1]

                # Try to resolve the account to see if it's a valid user or group
                try {
                    $account = [ADSI]"WinNT://$($env:COMPUTERNAME)/$accountName"
                    Write-EnhancedLog -Message "Resolved account: $accountName" -Level "INFO"
                }
                catch {
                    # Add orphaned SIDs to the list
                    $orphanedSIDs.Add([pscustomobject]@{
                            AccountName = $accountName
                            SID         = $_.PartComponent
                        })
                    Write-EnhancedLog -Message "Orphaned SID detected: $accountName" -Level "Warning"
                }
            }
        }
    }

    End {
        if ($orphanedSIDs.Count -eq 0) {
            Write-EnhancedLog -Message "No orphaned SIDs found in the '$GroupName' group." -Level "INFO"
        }
        else {
            Write-EnhancedLog -Message "Orphaned SIDs found: $($orphanedSIDs | Format-Table -AutoSize)" -Level "Warning"
        }

        Write-EnhancedLog -Message "Exiting Get-OrphanedSIDs function" -Level "Notice"
        return $orphanedSIDs
    }
}
