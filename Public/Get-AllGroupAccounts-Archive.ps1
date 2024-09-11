# function Get-AllGroupAccounts {
#     param (
#         [string]$GroupName = "Administrators"
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Get-AllGroupAccounts function for group '$GroupName'" -Level "Notice"
#         # Initialize a list to store all accounts
#         $allAccounts = [System.Collections.Generic.List[PSCustomObject]]::new()
#     }

#     Process {
#         # Get all group members
#         $admins = Get-GroupMembers -GroupName $GroupName

#         if ($admins.Count -gt 0) {
#             foreach ($admin in $admins) {
#                 # Extract the account name from the PartComponent
#                 $accountName = Extract-AccountName -PartComponent $admin.PartComponent

#                 if ($accountName) {
#                     # Try to resolve the account to check if it's orphaned
#                     $resolved = Resolve-Account -AccountName $accountName

#                     # Add the account to the list, flagging if it is orphaned or not
#                     $allAccounts.Add([pscustomobject]@{
#                         AccountName = $accountName
#                         SID         = $admin.PartComponent
#                         IsOrphaned  = -not $resolved
#                     })
                    
#                     # Log the status of the account
#                     if ($resolved) {
#                         Write-EnhancedLog -Message "Resolved account: $accountName" -Level "INFO"
#                     } else {
#                         Write-EnhancedLog -Message "Orphaned account detected: $accountName" -Level "WARNING"
#                     }
#                 }
#             }
#         }
#         else {
#             Write-EnhancedLog -Message "No members found in the '$GroupName' group." -Level "WARNING"
#         }
#     }

#     End {
#         if ($allAccounts.Count -eq 0) {
#             Write-EnhancedLog -Message "No accounts found in the '$GroupName' group." -Level "INFO"
#         }
#         else {
#             Write-EnhancedLog -Message "All accounts retrieved from '$GroupName':" -Level "INFO"

#             # Output the accounts to the log properly formatted as a string
#             $accountsSummary = $allAccounts | Out-String
#             Write-EnhancedLog -Message $accountsSummary -Level "INFO"
#         }

#         Write-EnhancedLog -Message "Exiting Get-AllGroupAccounts function" -Level "Notice"
#         return $allAccounts
#     }
# }
