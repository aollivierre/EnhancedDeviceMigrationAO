


# function Add-UserToGroup {
#     param (
#         [string]$UserName = 'TempUser',
#         [string]$GroupName = 'Administrators'
#     )

#     $group = [ADSI]"WinNT://./$GroupName,group"
#     $user = [ADSI]"WinNT://./$UserName,user"

#     # Check if user exists
#     try {
#         if (-not $user.PSBase.Name) {
#             Write-EnhancedLog -Message "User $UserName does not exist. Cannot add to group." -Level "ERROR"
#             return
#         }
#     }
#     catch {
#         Write-EnhancedLog -Message "User $UserName does not exist. Cannot add to group." -Level "ERROR"
#         return
#     }

#     try {
#         if (-not $group.PSBase.Invoke("IsMember", $user.PSBase.Path)) {
#             Write-EnhancedLog -Message "Adding $UserName to $GroupName group..." -Level "INFO"
#             $group.PSBase.Invoke("Add", $user.PSBase.Path)
#             Write-EnhancedLog -Message "$UserName has been successfully added to $GroupName group." -Level "INFO"
#         } else {
#             Write-EnhancedLog -Message "$UserName is already a member of the $GroupName group." -Level "INFO"
#         }
#     }
#     catch {
#         Write-EnhancedLog -Message "Error adding $UserName to $GroupName group: $_" -Level "ERROR"
#     }
# }

# # # Main Logic
# # Write-EnhancedLog -Message "Starting group member verification..." -Level "NOTICE"

# # # Verify current group members
# # Verify-GroupMembers -GroupName 'Administrators'

# # # Ensure TempUser is in the Administrators group
# # Add-UserToGroup -UserName 'TempUser' -GroupName 'Administrators'

# # Write-EnhancedLog -Message "Group member verification completed." -Level "NOTICE"
