# Function to filter and log interactive user sessions
function Get-InteractiveUsers {
    try {
        # Log the start of the function
        Write-EnhancedLog -Message "Starting Get-InteractiveUsers function" -Level "NOTICE"

        # Run the 'query user' command to get logged-in user sessions
        $sessions = query user | Select-Object -Skip 1 | ForEach-Object {
            # Parse each line to extract session information, skip invalid lines
            # Split on 2 or more spaces to handle spacing variations
            $fields = $_ -split '\s{2,}'

            # Some lines may not have all fields, skip them
            if ($fields.Count -ge 4) {
                [PSCustomObject]@{
                    UserName    = $fields[0]
                    SessionName = $fields[1]
                    ID          = $fields[2]
                    State       = $fields[3]
                }
            }
        }

        # Filter out system accounts and background service accounts
        # Wrap in @() to ensure it's always treated as an array
        $interactiveUsers = @($sessions | Where-Object {
                $_.UserName -notmatch "^(DWM-|UMFD-|SYSTEM|LOCAL SERVICE|NETWORK SERVICE)"
            })

        # Log the users found
        Write-EnhancedLog -Message "Found $($interactiveUsers.Count) interactive users" -Level "INFO"

        return $interactiveUsers

    }
    catch {
        Handle-Error -ErrorRecord $_
    }
    finally {
        Write-EnhancedLog -Message "Exiting Get-InteractiveUsers function" -Level "NOTICE"
    }
}


# Function to handle the interactive user session logic
# function Manage-UserSessions {
#     try {
#         Write-EnhancedLog -Message "Starting Manage-UserSessions function" -Level "NOTICE"
        
#         # Ensure $interactiveUsers is always treated as an array
#         $interactiveUsers = @(Get-InteractiveUsers)

#         if ($interactiveUsers.Count -gt 1) {
#             # Log multiple users and throw an error
#             Write-EnhancedLog -Message "Multiple interactive users logged in" -Level "WARNING"
#             $interactiveUsers | ForEach-Object {
#                 Write-EnhancedLog -Message "User: $($_.UserName)" -Level "WARNING"
#             }
#             throw "Error: More than one interactive user is logged in. Please log off all other user sessions except the currently logged-in one."
#         }
#         elseif ($interactiveUsers.Count -eq 1) {
#             # Log the single user and success message
#             Write-EnhancedLog -Message "Interactive user logged in: $($interactiveUsers[0].UserName)" -Level "INFO"
#             Write-EnhancedLog -Message "Success: Only one interactive user is logged in." -Level "NOTICE"
#         }
#         else {
#             # Log no users
#             Write-EnhancedLog -Message "No interactive users are currently logged in." -Level "ERROR"
#         }

#     } catch {
#         Handle-Error -ErrorRecord $_
#     } finally {
#         Write-EnhancedLog -Message "Exiting Manage-UserSessions function" -Level "NOTICE"
#     }
# }


function Show-UserSessionWarningForm {
    param (
        [array]$Users
    )
    

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object system.windows.forms.Form
    $form.Text = "Multiple Interactive Sessions Detected"
    $form.Size = New-Object System.Drawing.Size(400, 300)
    $form.StartPosition = "CenterScreen"
    
    # Create a label for warning
    $label = New-Object system.windows.forms.Label
    $label.Text = "Multiple interactive sessions are logged in. Please log off all other sessions."
    $label.Size = New-Object System.Drawing.Size(360, 40)
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $form.Controls.Add($label)

    # Create a listbox to show interactive users
    $listBox = New-Object system.windows.forms.ListBox
    $listBox.Size = New-Object System.Drawing.Size(350, 100)
    $listBox.Location = New-Object System.Drawing.Point(20, 70)
    $Users | ForEach-Object { $listBox.Items.Add($_.UserName) }
    $form.Controls.Add($listBox)

    # Create OK and Cancel buttons
    $okButton = New-Object system.windows.forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(220, 200)
    $okButton.Add_Click({
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        })
    $form.Controls.Add($okButton)

    $cancelButton = New-Object system.windows.forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(120, 200)
    $cancelButton.Add_Click({
            $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $form.Close()
        })
    $form.Controls.Add($cancelButton)

    # Show the form
    $form.Topmost = $true
    return $form.ShowDialog()
}


function Manage-UserSessions {
    [CmdletBinding()]
    param ()

  

    # Display the form to warn the user about multiple sessions
  

    try {
        Write-EnhancedLog -Message "Starting Manage-UserSessions function" -Level "NOTICE"

        # Loop until only one interactive user is logged in
        do {
            # Retrieve all interactive users
            $interactiveUsers = @(Get-InteractiveUsers)
            
            if ($interactiveUsers.Count -gt 1) {
                # Log multiple users and show warning
                Write-EnhancedLog -Message "Multiple interactive users logged in" -Level "WARNING"
                $interactiveUsers | ForEach-Object {
                    Write-EnhancedLog -Message "User: $($_.UserName)" -Level "WARNING"
                }

                # Show the Windows Form with user warning
                $result = Show-UserSessionWarningForm -Users $interactiveUsers

                # If user cancels, stop the script
                if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
                    Write-EnhancedLog -Message "User canceled the session management." -Level "ERROR"
                    throw "User canceled the session management."
                }

            }
            elseif ($interactiveUsers.Count -eq 1) {
                # Log success when only one user is logged in
                Write-EnhancedLog -Message "Interactive user logged in: $($interactiveUsers[0].UserName)" -Level "INFO"
                Write-EnhancedLog -Message "Success: Only one interactive user is logged in." -Level "NOTICE"
                break
            }
            else {
                Write-EnhancedLog -Message "No interactive users are currently logged in." -Level "ERROR"
                throw "No interactive users are currently logged in."
            }

            # Sleep before the next check
            Start-Sleep -Seconds 5

        } until ($interactiveUsers.Count -eq 1)

    }
    catch {
        Handle-Error -ErrorRecord $_
    }
    finally {
        Write-EnhancedLog -Message "Exiting Manage-UserSessions function" -Level "NOTICE"
    }
}



# # Main execution
# try {
#     Write-EnhancedLog -Message "Script execution started" -Level "NOTICE"
#     Manage-UserSessions
# } catch {
#     Handle-Error -ErrorRecord $_
# } finally {
#     Write-EnhancedLog -Message "Script execution finished" -Level "NOTICE"
# }
