function Add-UserToLocalAdminGroup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the username to add to the local admin group.")]
        [string]$Username
    )

    Process {
        Write-EnhancedLog -Message "Starting process to add user '$Username' to local Administrators group." -Level "NOTICE"

        # Verify if the user is already in the group using Get-EnhancedLocalGroupMembers
        $isMember = Get-EnhancedLocalGroupMembers -GroupName "Administrators" | Where-Object { $_.Account -eq $Username }

        if ($isMember) {
            Write-EnhancedLog -Message "User '$Username' is already a member of the Administrators group. No action required." -Level "INFO"
            return
        }

        # Use Add-LocalGroupMember to add the user to the local administrators group
        if ($PSCmdlet.ShouldProcess("Administrators group", "Adding user '$Username'")) {
            try {
                Add-LocalGroupMember -Group "Administrators" -Member $Username
                Write-EnhancedLog -Message "Successfully added '$Username' to the local Administrators group." -Level "SUCCESS"
            }
            catch {
                Write-EnhancedLog -Message "Failed to add user '$Username' to the local Administrators group: $($_.Exception.Message)" -Level "ERROR"
                throw
            }
        }

        Write-EnhancedLog -Message "Completed process to add user '$Username' to local Administrators group." -Level "NOTICE"
    }
}

function Create-LocalUserIfNotExists {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the username to create.")]
        [string]$Username,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the full Description for the new user.")]
        [string]$Description,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the password for the new user.")]
        [string]$Password
    )

    Process {
        Write-EnhancedLog -Message "Checking if user '$Username' exists." -Level "NOTICE"

        # Check if running in PowerShell 7 or later
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            Write-EnhancedLog -Message "Running in PowerShell 7. Importing LocalAccounts module using Windows PowerShell." -Level "NOTICE"
            try {
                # Import the LocalAccounts module from Windows PowerShell
                Import-Module -Name Microsoft.PowerShell.LocalAccounts -UseWindowsPowerShell -ErrorAction Stop
            }
            catch {
                Write-EnhancedLog -Message "Failed to import LocalAccounts module: $($_.Exception.Message)" -Level "ERROR"
                throw
            }
        }

        try {
            # Check if user exists using Get-LocalUser
            $user = Get-LocalUser -Name $Username -ErrorAction Stop
            Write-EnhancedLog -Message "User '$Username' already exists. No action required." -Level "INFO"
            return $true
        }
        catch {
            Write-EnhancedLog -Message "User '$Username' does not exist. Proceeding with creation..." -Level "NOTICE"

            if ($PSCmdlet.ShouldProcess("System", "Create local user '$Username'")) {
                try {
                    # Create the user if they do not exist
                    New-LocalUser -Name $Username -Description $Description -Password (ConvertTo-SecureString $Password -AsPlainText -Force)
                    Write-EnhancedLog -Message "Successfully created user '$Username'." -Level "SUCCESS"
                    return $true
                }
                catch {
                    Write-EnhancedLog -Message "Failed to create user '$Username': $($_.Exception.Message)" -Level "ERROR"
                    throw
                }
            }
        }

        Write-EnhancedLog -Message "Completed process to create user '$Username'." -Level "NOTICE"
        return $false
    }
}

function Ensure-UserInLocalAdminGroup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the username to manage.")]
        [string]$Username,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the full Description for the new user.")]
        [string]$Description,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the password for the new user.")]
        [string]$Password
    )

    Process {
        Write-EnhancedLog -Message "Ensuring user '$Username' is in the local Administrators group." -Level "NOTICE"

        # Step 1: Check if user exists, if not, create the user
        $userParams = @{
            Username    = $Username
            Description = $Description
            Password    = $Password
        }
        $userCreated = Create-LocalUserIfNotExists @userParams

        if ($userCreated) {
            # Step 2: Verifying user membership before adding to the local admin group using Get-EnhancedLocalGroupMembers
            $beforeMember = Get-EnhancedLocalGroupMembers -GroupName "Administrators" | Where-Object { $_.Account -eq $Username }

            if (-not $beforeMember) {
                Write-EnhancedLog -Message "User '$Username' is not a member of the local Administrators group." -Level "NOTICE"

                # Step 3: Add the user to the local admin group
                Add-UserToLocalAdminGroup -Username $Username
            }

            # Step 4: Verifying user membership after adding to the local admin group using Get-EnhancedLocalGroupMembers
            $afterMember = Get-EnhancedLocalGroupMembers -GroupName "Administrators" | Where-Object { $_.Account -eq $Username }

            if ($afterMember) {
                Write-EnhancedLog -Message "User '$Username' has been successfully added to the local Administrators group." -Level "SUCCESS"
            }
            else {
                Write-EnhancedLog -Message "User '$Username' was NOT added to the local Administrators group." -Level "ERROR"
            }
        }
        else {
            Write-EnhancedLog -Message "User '$Username' could not be created. Exiting process." -Level "ERROR"
        }

        Write-EnhancedLog -Message "Completed process to ensure user '$Username' is in the local Administrators group." -Level "NOTICE"
    }
}


# $params = @{
#     Username = "Tempuser005"
#     Description = "Temporary User 002"
#     Password = "SecurePassword123!"
# }

# Ensure-UserInLocalAdminGroup @params