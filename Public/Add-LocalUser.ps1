function Verify-GroupMembers {
    <#
    .SYNOPSIS
    Verifies members of a local group.
    .PARAMETER groupMembers
    An array of members in the local group.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$groupMembers
    )

    Begin {
        Write-EnhancedLog -Message "Starting Verify-GroupMembers function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        Write-EnhancedLog -Message "Verifying remaining members of the group." -Level "INFO"
        foreach ($member in $groupMembers) {
            try {
                $objSID = New-Object System.Security.Principal.SecurityIdentifier($member.SID)
                $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
                Write-EnhancedLog -Message "Valid member: $($objUser.Value), SID: $($member.SID)" -Level "INFO"
            }
            catch {
                Write-EnhancedLog -Message "Unable to resolve member: SID $($member.SID)" -Level "WARNING"
            }
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Verify-GroupMembers function" -Level "Notice"
    }
}

function Get-LocalUserAccount {
    <#
    .SYNOPSIS
    Checks if a local user exists and creates the user if necessary.
    .PARAMETER TempUser
    The username of the temporary local user.
    .PARAMETER TempUserPassword
    The password for the local user.
    .PARAMETER Description
    The description for the local user account.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TempUser,

        [Parameter(Mandatory = $true)]
        [string]$TempUserPassword,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-LocalUserAccount function for user '$TempUser'" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Checking if local user '$TempUser' exists." -Level "INFO"
            $userExists = Get-LocalUser -Name $TempUser -ErrorAction SilentlyContinue

            if (-not $userExists) {
                Write-EnhancedLog -Message "Creating Local User Account '$TempUser'." -Level "INFO"
                $Password = ConvertTo-SecureString -AsPlainText $TempUserPassword -Force
                New-LocalUser -Name $TempUser -Password $Password -Description $Description -AccountNeverExpires
                Write-EnhancedLog -Message "Local user account '$TempUser' created successfully." -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Local user account '$TempUser' already exists." -Level "WARNING"
            }

            return $userExists

        }
        catch {
            Write-EnhancedLog -Message "Failed to retrieve or create user '$TempUser': $($_.Exception.Message)" -Level "ERROR"
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-LocalUserAccount function" -Level "Notice"
    }
}

function Get-LocalGroupWithMembers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Group
    )

    try {
        Write-EnhancedLog -Message "Retrieving group '$Group' for membership check." -Level "INFO"
        $group = Get-LocalGroup -Name $Group -ErrorAction Stop

        Write-EnhancedLog -Message "Group '$Group' found. Retrieving group members." -Level "INFO"
        $groupMembers = Get-LocalGroupMember -Group $Group -ErrorAction Stop

        Write-EnhancedLog -Message "Group '$Group' has $($groupMembers.Count) members." -Level "INFO"
        return $groupMembers

    }
    catch {
        Write-EnhancedLog -Message "Error retrieving group '$Group' or members: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Check-UserGroupMembership {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TempUser,

        [Parameter(Mandatory = $true)]
        [array]$GroupMembers
    )

    try {
        Write-EnhancedLog -Message "Checking if user '$TempUser' is a member of the group." -Level "INFO"
        $userSID = (Get-LocalUser -Name $TempUser -ErrorAction Stop).SID
        $memberExists = $false

        foreach ($member in $GroupMembers) {
            Write-EnhancedLog -Message "Checking group member '$($member.Name)' (SID: $($member.SID))." -Level "DEBUG"
            if ($member.SID -eq $userSID) {
                Write-EnhancedLog -Message "User '$TempUser' is already a member of the group." -Level "INFO"
                $memberExists = $true
                break
            }
        }

        return $memberExists

    }
    catch {
        Write-EnhancedLog -Message "Error checking user group membership: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Add-UserToLocalGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TempUser,

        [Parameter(Mandatory = $true)]
        [string]$Group
    )

    try {
        Write-EnhancedLog -Message "Adding user '$TempUser' to group '$Group'." -Level "INFO"
        Add-LocalGroupMember -Group $Group -Member $TempUser -ErrorAction Stop
        Write-EnhancedLog -Message "User '$TempUser' added to group '$Group'." -Level "INFO"

    }
    catch [Microsoft.PowerShell.Commands.AddLocalGroupMemberCommand+MemberExistsException] {
        Write-EnhancedLog -Message "User '$TempUser' is already a member of the group '$Group'." -Level "WARNING"
    }
    catch {
        Write-EnhancedLog -Message "Failed to add user '$TempUser' to group '$Group': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Add-LocalUser {
    <#
    .SYNOPSIS
    Adds a local user and ensures they are part of the correct group.
    .PARAMETER TempUser
    The username of the temporary local user.
    .PARAMETER TempUserPassword
    The password for the local user.
    .PARAMETER Description
    The description for the local user account.
    .PARAMETER Group
    The group to add the local user to.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TempUser,

        [Parameter(Mandatory = $true)]
        [string]$TempUserPassword,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string]$Group
    )

    Begin {
        Write-EnhancedLog -Message "Starting Add-LocalUser function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Main script to clean orphaned SIDs and verify group members
      
        # Step 1: Remove orphaned SIDs
        # Example usage to remove orphaned SIDs from the "Administrators" group
        # $params = @{
        #     Group = "Administrators"
        # }
        # Remove-OrphanedSIDs @params


        Remove-OrphanedSIDsFromAdministratorsGroup


        # Step 2: Retrieve group members
        $groupMembers = Get-LocalGroupWithMembers -Group $Group

        if ($groupMembers) {
            # Step 3: Verify the remaining group members
            Verify-GroupMembers -groupMembers $groupMembers
        }
        

    }

    Process {
        try {
            # Step 1: Check or create local user
            $userExists = Get-LocalUserAccount -TempUser $TempUser -TempUserPassword $TempUserPassword -Description $Description

            # Step 2: Retrieve group and its members
            $groupMembers = Get-LocalGroupWithMembers -Group $Group

            # Step 3: Check if user is a member of the group
            $isMember = Check-UserGroupMembership -TempUser $TempUser -GroupMembers $groupMembers

            # Step 4: Add user to group if not a member
            if (-not $isMember) {
                Add-UserToLocalGroup -TempUser $TempUser -Group $Group
            }

            # Step 5: Remove orphaned SIDs and verify group members
            # Example usage to remove orphaned SIDs from the "Administrators" group
            # $params = @{
            #     Group = "Administrators"
            # }
            # Remove-OrphanedSIDs @params

            Remove-OrphanedSIDsFromAdministratorsGroup

            # Retrieve group members
            $groupMembers = Get-LocalGroupWithMembers -Group $Group

            if ($groupMembers) {
                # Verify the remaining group members
                Verify-GroupMembers -groupMembers $groupMembers
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Add-LocalUser: $($_.Exception.Message)" -Level "ERROR"
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Add-LocalUser function" -Level "Notice"
    }
}