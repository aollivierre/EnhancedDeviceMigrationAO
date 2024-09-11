# # # function Verify-GroupMembers {
# # #     [CmdletBinding()]
# # #     param (
# # #         [Parameter(Mandatory = $true)]
# # #         [array]$groupMembers
# # #     )

# # #     Begin {
# # #         Write-EnhancedLog -Message "Starting Verify-GroupMembers function" -Level "Notice"
# # #         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
# # #     }

# # #     Process {
# # #         Write-EnhancedLog -Message "Verifying remaining members of the group." -Level "INFO"
# # #         foreach ($member in $groupMembers) {
# # #             try {
# # #                 # Ensure the SID is valid before processing
# # #                 if ($member.SID) {
# # #                     $objSID = New-Object System.Security.Principal.SecurityIdentifier($member.SID)
# # #                     $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
# # #                     Write-EnhancedLog -Message "Valid member: $($objUser.Value), SID: $($member.SID)" -Level "INFO"
# # #                 }
# # #                 else {
# # #                     Write-EnhancedLog -Message "Invalid or missing SID for member $($member.Name)" -Level "WARNING"
# # #                 }
# # #             }
# # #             catch {
# # #                 Write-EnhancedLog -Message "Unexpected error resolving member: SID $($member.SID). Error: $($_.Exception.Message)" -Level "ERROR"
# # #             }
# # #         }
# # #     }

# # #     End {
# # #         Write-EnhancedLog -Message "Exiting Verify-GroupMembers function" -Level "Notice"
# # #     }
# # # }




# # function Get-LocalUserAccount {
# #     <#
# #     .SYNOPSIS
# #     Checks if a local user exists and creates the user if necessary.
# #     .PARAMETER TempUser
# #     The username of the temporary local user.
# #     .PARAMETER TempUserPassword
# #     The password for the local user.
# #     .PARAMETER Description
# #     The description for the local user account.
# #     #>

# #     [CmdletBinding()]
# #     param (
# #         [Parameter(Mandatory = $true)]
# #         [string]$TempUser,

# #         [Parameter(Mandatory = $true)]
# #         [string]$TempUserPassword,

# #         [Parameter(Mandatory = $true)]
# #         [string]$Description
# #     )

# #     Begin {
# #         Write-EnhancedLog -Message "Starting Get-LocalUserAccount function for user '$TempUser'" -Level "Notice"
# #         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
# #     }

# #     Process {
# #         try {
# #             Write-EnhancedLog -Message "Checking if local user '$TempUser' exists." -Level "INFO"
# #             $userExists = Get-LocalUser -Name $TempUser -ErrorAction SilentlyContinue

# #             if (-not $userExists) {
# #                 Write-EnhancedLog -Message "Creating Local User Account '$TempUser'." -Level "INFO"
# #                 $Password = ConvertTo-SecureString -AsPlainText $TempUserPassword -Force
# #                 New-LocalUser -Name $TempUser -Password $Password -Description $Description -AccountNeverExpires
# #                 Write-EnhancedLog -Message "Local user account '$TempUser' created successfully." -Level "INFO"
# #             }
# #             else {
# #                 Write-EnhancedLog -Message "Local user account '$TempUser' already exists." -Level "WARNING"
# #             }

# #             return $userExists

# #         }
# #         catch {
# #             Write-EnhancedLog -Message "Failed to retrieve or create user '$TempUser': $($_.Exception.Message)" -Level "ERROR"
# #             throw
# #         }
# #     }

# #     End {
# #         Write-EnhancedLog -Message "Exiting Get-LocalUserAccount function" -Level "Notice"
# #     }
# # }

# # # # function Get-LocalGroupWithMembers {
# # # #     [CmdletBinding()]
# # # #     param (
# # # #         [Parameter(Mandatory = $true)]
# # # #         [string]$Group
# # # #     )

# # # #     try {
# # # #         Write-EnhancedLog -Message "Retrieving group '$Group' for membership check." -Level "INFO"
# # # #         $group = Get-LocalGroup -Name $Group -ErrorAction Stop

# # # #         Write-EnhancedLog -Message "Group '$Group' found. Retrieving group members." -Level "INFO"
# # # #         $groupMembers = Get-LocalGroupMember -Group $Group -ErrorAction Stop

# # # #         Write-EnhancedLog -Message "Group '$Group' has $($groupMembers.Count) members." -Level "INFO"
# # # #         return $groupMembers

# # # #     }
# # # #     catch {
# # # #         Write-EnhancedLog -Message "Error retrieving group '$Group' or members: $($_.Exception.Message)" -Level "ERROR"
# # # #         throw
# # # #     }
# # # # }

# # # function Check-UserGroupMembership {
# # #     [CmdletBinding()]
# # #     param (
# # #         [Parameter(Mandatory = $true)]
# # #         [string]$TempUser,

# # #         [Parameter(Mandatory = $true)]
# # #         [array]$GroupMembers
# # #     )

# # #     try {
# # #         Write-EnhancedLog -Message "Checking if user '$TempUser' is a member of the group." -Level "INFO"
# # #         $userSID = (Get-LocalUser -Name $TempUser -ErrorAction Stop).SID
# # #         $memberExists = $false

# # #         foreach ($member in $GroupMembers) {
# # #             Write-EnhancedLog -Message "Checking group member '$($member.Name)' (SID: $($member.SID))." -Level "DEBUG"
# # #             if ($member.SID -eq $userSID) {
# # #                 Write-EnhancedLog -Message "User '$TempUser' is already a member of the group." -Level "INFO"
# # #                 $memberExists = $true
# # #                 break
# # #             }
# # #         }

# # #         return $memberExists

# # #     }
# # #     catch {
# # #         Write-EnhancedLog -Message "Error checking user group membership: $($_.Exception.Message)" -Level "ERROR"
# # #         throw
# # #     }
# # # }

# # # function Add-UserToLocalGroup {
# # #     [CmdletBinding()]
# # #     param (
# # #         [Parameter(Mandatory = $true)]
# # #         [string]$TempUser,
# # #         [Parameter(Mandatory = $true)]
# # #         [string]$Group
# # #     )

# # #     try {
# # #         Write-EnhancedLog -Message "Checking if user '$TempUser' is already a member of group '$Group'." -Level "INFO"
# # #         # $groupMembers = Get-LocalGroupMember -Group $Group -ErrorAction Stop
# # #         $groupMembers = Get-GroupMembers -GroupName $Group -ErrorAction Stop

# # #         # Check if the user is already a member of the group
# # #         if ($groupMembers.Name -contains $TempUser) {
# # #             Write-EnhancedLog -Message "User '$TempUser' is already a member of the group '$Group'." -Level "INFO"
# # #         }
# # #         else {
# # #             Write-EnhancedLog -Message "Adding user '$TempUser' to group '$Group'." -Level "INFO"
# # #             Add-LocalGroupMember -Group $Group -Member $TempUser -ErrorAction Stop
# # #             Write-EnhancedLog -Message "User '$TempUser' added to group '$Group'." -Level "INFO"
# # #         }
# # #     }
# # #     catch {
# # #         Write-EnhancedLog -Message "Failed to add user '$TempUser' to group '$Group': $($_.Exception.Message)" -Level "ERROR"
# # #         throw
# # #     }
# # # }





# # # function Add-LocalUser {
# # #     [CmdletBinding()]
# # #     param (
# # #         [Parameter(Mandatory = $true)]
# # #         [string]$TempUser,

# # #         [Parameter(Mandatory = $true)]
# # #         [string]$TempUserPassword,

# # #         [Parameter(Mandatory = $true)]
# # #         [string]$Description,

# # #         [Parameter(Mandatory = $true)]
# # #         [string]$Group = "Administrators"
# # #     )

# # #     Begin {
# # #         Write-EnhancedLog -Message "Starting Add-LocalUser function" -Level "Notice"
# # #         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
# # #     }

# # #     Process {
# # #         try {
# # #             # Step 1: Check or create local user
# # #             $userExists = Get-LocalUserAccount -TempUser $TempUser -TempUserPassword $TempUserPassword -Description $Description

# # #             # Step 2: Retrieve group members using Get-GroupMembers function instead of Get-LocalGroupMember
# # #             $groupMembers = Get-GroupMembers -GroupName $Group

# # #             if ($groupMembers) {
# # #                 # Step 3: Check if user is already a member of the group
# # #                 $isMember = $false
# # #                 foreach ($member in $groupMembers) {
# # #                     $accountName = Extract-AccountName -PartComponent $member.PartComponent
# # #                     if ($accountName -eq $TempUser) {
# # #                         $isMember = $true
# # #                         break
# # #                     }
# # #                 }

# # #                 # Step 4: Add user to group if not already a member
# # #                 if (-not $isMember) {
# # #                     Add-UserToLocalGroup -TempUser $TempUser -Group $Group
# # #                 }
# # #                 else {
# # #                     Write-EnhancedLog -Message "User '$TempUser' is already a member of the group '$Group'." -Level "WARNING"
# # #                 }

# # #                 # Step 5: Verify the group members after modification
# # #                 Verify-GroupMembers -groupMembers $groupMembers
# # #             }
# # #             else {
# # #                 Write-EnhancedLog -Message "No members found in group '$Group'." -Level "WARNING"
# # #             }
# # #         }
# # #         catch {
# # #             Write-EnhancedLog -Message "An error occurred in Add-LocalUser: $($_.Exception.Message)" -Level "ERROR"
# # #             throw
# # #         }
# # #     }

# # #     End {
# # #         Write-EnhancedLog -Message "Exiting Add-LocalUser function" -Level "Notice"
# # #     }
# # # }



# # # # function Add-LocalUser {
# # # #     <#
# # # #     .SYNOPSIS
# # # #     Adds a local user and ensures they are part of the correct group.
# # # #     .PARAMETER TempUser
# # # #     The username of the temporary local user.
# # # #     .PARAMETER TempUserPassword
# # # #     The password for the local user.
# # # #     .PARAMETER Description
# # # #     The description for the local user account.
# # # #     .PARAMETER Group
# # # #     The group to add the local user to.
# # # #     #>

# # # #     [CmdletBinding()]
# # # #     param (
# # # #         [Parameter(Mandatory = $true)]
# # # #         [string]$TempUser,

# # # #         [Parameter(Mandatory = $true)]
# # # #         [string]$TempUserPassword,

# # # #         [Parameter(Mandatory = $true)]
# # # #         [string]$Description,

# # # #         [Parameter(Mandatory = $true)]
# # # #         [string]$Group
# # # #     )

# # # #     Begin {
# # # #         Write-EnhancedLog -Message "Starting Add-LocalUser function" -Level "Notice"
# # # #         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

# # # #         # Main script to clean orphaned SIDs and verify group members
      
# # # #         # Step 1: Remove orphaned SIDs
# # # #         # Example usage to remove orphaned SIDs from the "Administrators" group
# # # #         # $params = @{
# # # #         #     Group = "Administrators"
# # # #         # }
# # # #         # Remove-OrphanedSIDs @params


# # # #         # Remove-OrphanedSIDsFromAdministratorsGroup


# # # #         # $GetGroupMembers = @{
# # # #         #     GroupName = "Administrators"
# # # #         # }
# # # #         # $groupMembers = Get-GroupMembers @GetGroupMembers


# # # #         # $groupMembers = Get-OrphanedSIDs
# # # #         $groupMembers = Get-AllGroupAccounts -GroupName "Administrators"
# # # #         # $accounts | Format-Table -AutoSize



# # # #         # Wait-Debugger

# # # #         # Step 2: Retrieve group members
# # # #         # $groupMembers = Get-LocalGroupWithMembers -Group $Group

# # # #         if ($groupMembers) {
# # # #             # Step 3: Verify the remaining group members
# # # #             Verify-GroupMembers -groupMembers $groupMembers
# # # #         }
        
# # # #         Wait-Debugger

# # # #     }

# # # #     Process {
# # # #         try {
# # # #             # Step 1: Check or create local user
# # # #             $userExists = Get-LocalUserAccount -TempUser $TempUser -TempUserPassword $TempUserPassword -Description $Description


# # # #             $GetGroupMembers = @{
# # # #                 GroupName = "Administrators"
# # # #             }
# # # #             $groupMembers = Get-GroupMembers @GetGroupMembers

# # # #             # Step 2: Retrieve group and its members
# # # #             # $groupMembers = Get-LocalGroupWithMembers -Group $Group

# # # #             # Step 3: Check if user is a member of the group
# # # #             $isMember = Check-UserGroupMembership -TempUser $TempUser -GroupMembers $groupMembers

# # # #             # Step 4: Add user to group if not a member
# # # #             if (-not $isMember) {
# # # #                 Add-UserToLocalGroup -TempUser $TempUser -Group $Group
# # # #             }

# # # #             # Step 5: Remove orphaned SIDs and verify group members
# # # #             # Example usage to remove orphaned SIDs from the "Administrators" group
# # # #             # $params = @{
# # # #             #     Group = "Administrators"
# # # #             # }
# # # #             # Remove-OrphanedSIDs @params

# # # #             # Remove-OrphanedSIDsFromAdministratorsGroup


# # # #             $GetGroupMembers = @{
# # # #                 GroupName = "Administrators"
# # # #             }
# # # #             $groupMembers = Get-GroupMembers @GetGroupMembers
    

# # # #             # Retrieve group members
# # # #             # $groupMembers = Get-LocalGroupWithMembers -Group $Group

# # # #             if ($groupMembers) {
# # # #                 # Verify the remaining group members
# # # #                 Verify-GroupMembers -groupMembers $groupMembers
# # # #             }
# # # #         }
# # # #         catch {
# # # #             Write-EnhancedLog -Message "An error occurred in Add-LocalUser: $($_.Exception.Message)" -Level "ERROR"
# # # #             throw
# # # #         }
# # # #     }

# # # #     End {
# # # #         Write-EnhancedLog -Message "Exiting Add-LocalUser function" -Level "Notice"
# # # #     }
# # # # }


























# # function Get-GroupMembers {
# #     param (
# #         [string]$GroupName = "Administrators"
# #     )

# #     Begin {
# #         Write-EnhancedLog -Message "Retrieving members of the '$GroupName' group." -Level "INFO"
# #     }

# #     Process {
# #         try {
# #             Write-EnhancedLog -Message "Attempting to retrieve members of the '$GroupName' group." -Level "INFO"
# #             $groupPattern = [regex]::Escape($GroupName)
# #             $admins = Get-WmiObject -Class Win32_GroupUser | Where-Object { $_.GroupComponent -match $groupPattern }

# #             $count = $admins.Count
# #             Write-EnhancedLog -Message "Found $count members in the '$GroupName' group." -Level "INFO"

# #             if ($count -eq 0) {
# #                 Write-EnhancedLog -Message "No members found in the '$GroupName' group." -Level "WARNING"
# #             }

# #             return $admins
# #         }
# #         catch {
# #             Write-EnhancedLog -Message "Failed to retrieve members of the '$GroupName' group: $($_.Exception.Message)" -Level "ERROR"
# #             Handle-Error -ErrorRecord $_
# #             throw
# #         }
# #     }
# # }





# # function Verify-GroupMembers {
# #     [CmdletBinding()]
# #     param (
# #         [Parameter(Mandatory = $true)]
# #         [array]$groupMembers
# #     )

# #     Begin {
# #         Write-EnhancedLog -Message "Starting Verify-GroupMembers function" -Level "Notice"
# #         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
# #     }

# #     Process {
# #         Write-EnhancedLog -Message "Verifying remaining members of the group." -Level "INFO"
        
# #         foreach ($member in $groupMembers) {
# #             try {
# #                 # Attempt to extract the SID from the PartComponent property
# #                 $partComponent = $member.PartComponent
# #                 if ($partComponent -match 'Win32_UserAccount.Domain="[^"]+",Name="([^"]+)"') {
# #                     $accountName = $matches[1]

# #                     Write-EnhancedLog -Message "Attempting to resolve account: $accountName" -Level "INFO"
                    
# #                     # Create SID from the account name
# #                     $objSID = New-Object System.Security.Principal.SecurityIdentifier($accountName)
# #                     $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
                    
# #                     Write-EnhancedLog -Message "Valid member: $($objUser.Value), SID: $($member.PartComponent)" -Level "INFO"
# #                 } else {
# #                     Write-EnhancedLog -Message "Invalid or missing SID for member: $($member.PartComponent)" -Level "WARNING"
# #                 }
# #             }
# #             catch {
# #                 Write-EnhancedLog -Message "Unable to resolve member: $($member.PartComponent). Error: $($_.Exception.Message)" -Level "ERROR"
# #             }
# #         }
# #     }

# #     End {
# #         Write-EnhancedLog -Message "Exiting Verify-GroupMembers function" -Level "Notice"
# #     }
# # }









# # function Add-LocalUser {
# #     [CmdletBinding()]
# #     param (
# #         [Parameter(Mandatory = $true)]
# #         [string]$TempUser,

# #         [Parameter(Mandatory = $true)]
# #         [string]$TempUserPassword,

# #         [Parameter(Mandatory = $true)]
# #         [string]$Description,

# #         [Parameter(Mandatory = $true)]
# #         [string]$Group = "Administrators"
# #     )

# #     Begin {
# #         Write-EnhancedLog -Message "Starting Add-LocalUser function" -Level "Notice"
# #         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
# #     }

# #     Process {
# #         try {
# #             # Step 1: Check or create local user
# #             $userExists = Get-LocalUserAccount -TempUser $TempUser -TempUserPassword $TempUserPassword -Description $Description

# #             # Step 2: Retrieve group members using Get-GroupMembers
# #             $groupMembers = Get-GroupMembers -GroupName $Group

# #             if ($groupMembers) {
# #                 # Step 3: Check if user is already a member of the group
# #                 $isMember = $false
# #                 foreach ($member in $groupMembers) {
# #                     $accountName = Extract-AccountName -PartComponent $member.PartComponent
# #                     if ($accountName -eq $TempUser) {
# #                         $isMember = $true
# #                         break
# #                     }
# #                 }

# #                 # Step 4: Add user to group if not already a member
# #                 if (-not $isMember) {
# #                     Add-UserToLocalGroup -TempUser $TempUser -Group $Group
# #                 }
# #                 else {
# #                     Write-EnhancedLog -Message "User '$TempUser' is already a member of the group '$Group'." -Level "WARNING"
# #                 }

# #                 # Step 5: Verify the group members after modification
# #                 Verify-GroupMembers -groupMembers $groupMembers
# #             }
# #             else {
# #                 Write-EnhancedLog -Message "No members found in group '$Group'." -Level "WARNING"
# #             }
# #         }
# #         catch {
# #             Write-EnhancedLog -Message "An error occurred in Add-LocalUser: $($_.Exception.Message)" -Level "ERROR"
# #             throw
# #         }
# #     }

# #     End {
# #         Write-EnhancedLog -Message "Exiting Add-LocalUser function" -Level "Notice"
# #     }
# # }







# function Get-GroupMembers {
#     param (
#         [string]$GroupName = 'Administrators'
#     )

#     # Retrieve all group members via WMI
#     try {
#         $group = Get-WmiObject -Class Win32_Group -Filter "Name='$GroupName'"
#         $members = $group.GetRelated("Win32_UserAccount")
#         if (!$members) {
#             Write-EnhancedLog -Message "No members found in group $GroupName." -Level "WARNING"
#         }
#         return $members
#     }
#     catch {
#         Write-EnhancedLog -Message "Error retrieving members from group $GroupName $_" -Level "ERROR"
#         return $null
#     }
# }

# function Resolve-SID {
#     param (
#         [string]$AccountName
#     )

#     try {
#         $account = Get-WmiObject -Class Win32_UserAccount -Filter "Name='$AccountName'"
#         if ($account) {
#             $sid = New-Object System.Security.Principal.SecurityIdentifier($account.SID)
#             return $sid
#         } else {
#             Write-EnhancedLog -Message "Unable to resolve SID for $AccountName." -Level "WARNING"
#             return $null
#         }
#     }
#     catch {
#         Write-EnhancedLog -Message "Error resolving SID for $AccountName $_" -Level "ERROR"
#         return $null
#     }
# }





# # # Main Logic
# # Write-EnhancedLog -Message "Starting group member verification..." -Level "NOTICE"

# # # Verify current group members
# # Verify-GroupMembers -GroupName 'Administrators'

# # # Ensure TempUser is in the Administrators group
# # Add-UserToGroup -UserName 'TempUser' -GroupName 'Administrators'

# # Write-EnhancedLog -Message "Group member verification completed." -Level "NOTICE"








