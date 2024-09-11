function Get-EnhancedLocalGroupMembers {
    <#
    .SYNOPSIS
    Retrieves and logs members of a specified local group, differentiating between user and system accounts.

    .DESCRIPTION
    The Get-EnhancedLocalGroupMembers function retrieves all members of a specified local group. It logs the retrieval process, handles errors gracefully, and differentiates between user, system accounts, and built-in groups. It also provides a summary report with success and failure counts.

    .PARAMETER GroupName
    The name of the local group to retrieve members from (default is "Administrators").

    .PARAMETER PassThru
    Allows pipeline support and passes the objects to the pipeline for further processing.

    .EXAMPLE
    Get-EnhancedLocalGroupMembers -GroupName "Administrators" | Format-Table
    Retrieves members of the "Administrators" group and formats the output as a table.

    .EXAMPLE
    "Administrators", "Users" | Get-EnhancedLocalGroupMembers
    Retrieves members from multiple groups using pipeline input.
    #>

    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Medium")]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Name of the local group to retrieve members from.")]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName = "Administrators",

        [Parameter(Mandatory = $false, HelpMessage = "Passes objects down the pipeline.")]
        [switch]$PassThru
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-EnhancedLocalGroupMembers function for group '$GroupName'" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Initialize a System.Collections.Generic.List object to store group members efficiently
        $groupMembers = [System.Collections.Generic.List[PSCustomObject]]::new()
        $successCount = 0
        $failureCount = 0
    }

    Process {
        if ($PSCmdlet.ShouldProcess("Group '$GroupName'", "Retrieve group members")) {
            try {
                $group = [ADSI]"WinNT://./$GroupName,group"
                if (!$group) {
                    Write-EnhancedLog -Message "Group '$GroupName' not found." -Level "ERROR"
                    throw "Group '$GroupName' not found."
                }
                Write-EnhancedLog -Message "Group '$GroupName' found. Retrieving members..." -Level "INFO"

                $members = $group.psbase.Invoke("Members")
                foreach ($member in $members) {
                    try {
                        # Get the full name of the account
                        $accountName = $member.GetType().InvokeMember("Name", 'GetProperty', $null, $member, $null)

                        # Determine if it's a user or system account
                        $accountType = if ($accountName -match "^NT AUTHORITY") {
                            "System Account"
                        } elseif ($accountName -match "^BUILTIN") {
                            "Built-in Group"
                        } else {
                            "User Account"
                        }

                        # Create a custom object for each account and add it to the list efficiently
                        $groupMember = [PSCustomObject]@{
                            Account = $accountName
                            Type    = $accountType
                        }

                        $groupMembers.Add($groupMember)
                        $successCount++
                        
                        # Log the account details
                        Write-EnhancedLog -Message "Account: $accountName, Type: $accountType" -Level "INFO"

                        # Output the object to the pipeline if PassThru is enabled
                        if ($PassThru) {
                            $groupMember
                        }
                    }
                    catch {
                        Write-EnhancedLog -Message "Failed to process member: $($_.Exception.Message)" -Level "WARNING"
                        $failureCount++
                    }
                }
            }
            catch {
                Write-EnhancedLog -Message "Error retrieving group members for group '$GroupName': $($_.Exception.Message)" -Level "ERROR"
                Handle-Error -ErrorRecord $_
                throw
            }
        } else {
            Write-EnhancedLog -Message "Operation skipped due to WhatIf or Confirm." -Level "INFO"
        }
    }

    End {
        Write-EnhancedLog -Message "Finalizing the member retrieval process for group '$GroupName'" -Level "INFO"
        if ($groupMembers.Count -gt 0) {
            Write-EnhancedLog -Message "Successfully retrieved members for group '$GroupName'." -Level "INFO"
        }
        else {
            Write-EnhancedLog -Message "No members found for group '$GroupName'." -Level "WARNING"
        }

        # Output the summary report
        Show-SummaryReport -SuccessCount $successCount -FailureCount $failureCount

        # Output the list of group members only if PassThru is not enabled
        if (-not $PassThru) {
            $groupMembers
        }
    }
}

# Summary Report Function
function Show-SummaryReport {
    param (
        [int]$SuccessCount,
        [int]$FailureCount
    )

    $totalCount = $SuccessCount + $FailureCount

    # Output the summary with color coding
    Write-Host "Summary Report" -ForegroundColor Cyan
    Write-Host "Total Members Processed: $totalCount" -ForegroundColor Yellow
    Write-Host "Success: $SuccessCount" -ForegroundColor Green
    Write-Host "Failures: $FailureCount" -ForegroundColor Red
}

# Example usage:
# $params = @{
#     GroupName    = "Administrators"
# }
# Get-EnhancedLocalGroupMembers @params

# Example pipeline usage:
# "Administrators", "Users" | Get-EnhancedLocalGroupMembers -PassThru




























# function Add-UserToLocalAdminGroup {
#     [CmdletBinding(SupportsShouldProcess = $true)]
#     param (
#         [Parameter(Mandatory = $true, HelpMessage = "Specify the username to add to the local admin group.")]
#         [string]$Username
#     )

#     Process {
#         # Use ADSI to add the user to the local administrators group
#         if ($PSCmdlet.ShouldProcess("Administrators group", "Adding user '$Username'")) {
#             try {
#                 $adminGroup = [ADSI]"WinNT://./Administrators,group"
#                 $user = [ADSI]"WinNT://./$Username,user"
#                 $adminGroup.Add($user.PSBase.Path)
#                 Write-Host "Successfully added $Username to the local Administrators group." -ForegroundColor Green
#             }
#             catch {
#                 Write-Host "Failed to add user: $($_.Exception.Message)" -ForegroundColor Red
#             }
#         }
#     }
# }


# function Verify-UserMembershipBefore {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true, HelpMessage = "Specify the username to verify.")]
#         [string]$Username
#     )

#     Process {
#         Write-Host "Verifying if '$Username' is a member of the local Administrators group before operation..." -ForegroundColor Yellow

#         # Get the list of current members
#         $admins = Get-EnhancedLocalGroupMembers -GroupName "Administrators"
#         $userMembership = $admins | Where-Object { $_.Account -eq $Username }

#         if ($userMembership) {
#             Write-Host "User '$Username' is already a member of the local Administrators group." -ForegroundColor Cyan
#             return $true
#         }
#         else {
#             Write-Host "User '$Username' is NOT a member of the local Administrators group." -ForegroundColor Red
#             return $false
#         }
#     }
# }




# function Verify-UserMembershipAfter {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true, HelpMessage = "Specify the username to verify.")]
#         [string]$Username
#     )

#     Process {
#         Write-Host "Verifying if '$Username' has been successfully added to the local Administrators group..." -ForegroundColor Yellow

#         # Get the list of current members
#         $admins = Get-EnhancedLocalGroupMembers -GroupName "Administrators"
#         $userMembership = $admins | Where-Object { $_.Account -eq $Username }

#         if ($userMembership) {
#             Write-Host "User '$Username' has been successfully added to the local Administrators group." -ForegroundColor Green
#             return $true
#         }
#         else {
#             Write-Host "User '$Username' was NOT added to the local Administrators group." -ForegroundColor Red
#             return $false
#         }
#     }
# }





# function Verify-GroupMemberships {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true, HelpMessage = "Specify the username to verify.")]
#         [string]$Username
#     )

#     Process {
#         Write-Host "Verifying group memberships for user '$Username'..." -ForegroundColor Yellow

#         try {
#             $user = [ADSI]"WinNT://./$Username,user"
#             $groups = $user.Invoke("Groups")

#             foreach ($group in $groups) {
#                 $groupName = $group.GetType().InvokeMember("Name", 'GetProperty', $null, $group, $null)
#                 Write-Host "$Username is a member of group: $groupName" -ForegroundColor Cyan
#             }
#         }
#         catch {
#             Write-Host "Failed to retrieve group memberships for '$Username': $($_.Exception.Message)" -ForegroundColor Red
#         }
#     }
# }





# # Verifying before
# $beforeMember = Verify-UserMembershipBefore -Username "Admin-Abdullah"
# Verify-GroupMemberships -Username "Admin-Abdullah"

# # Add user if not already a member
# if (-not $beforeMember) {
#     Add-UserToLocalAdminGroup -Username "Admin-Abdullah"
# }

# # Verifying after
# Verify-UserMembershipAfter -Username "Admin-Abdullah"
# Verify-GroupMemberships -Username "Admin-Abdullah"






