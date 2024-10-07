function Show-DeviceStatusForm {

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $dsregStatus = Get-DSRegStatus

    # Initialize the form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Device Status"
    $form.Size = New-Object System.Drawing.Size(400, 300)
    $form.StartPosition = "CenterScreen"
    $form.WindowState = 'Normal'    # Ensure form is not minimized
    $form.TopMost = $true           # Bring the form to the top

    # Add label to display status
    $label = New-Object System.Windows.Forms.Label
    $label.Size = New-Object System.Drawing.Size(350, 200)
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Font = New-Object System.Drawing.Font("Arial", 10)

    # Check the device join status and build the status message
    $statusMessage = ""
    if ($dsregStatus.IsWorkgroup) {
        $statusMessage += "Device is Workgroup joined (not Azure AD, Hybrid, or On-prem Joined)." + [Environment]::NewLine
    }
    elseif ($dsregStatus.IsAzureADJoined -and -not $dsregStatus.IsHybridJoined) {
        $statusMessage += "Device is Azure AD Joined." + [Environment]::NewLine
    }
    elseif ($dsregStatus.IsHybridJoined) {
        $statusMessage += "Device is Hybrid Joined (both On-prem and Azure AD Joined)." + [Environment]::NewLine
    }
    elseif ($dsregStatus.IsOnPremJoined) {
        $statusMessage += "Device is On-prem Joined only." + [Environment]::NewLine
    }

    # Check the MDM enrollment status
    if ($dsregStatus.IsMDMEnrolled) {
        $statusMessage += "Device is Intune Enrolled." + [Environment]::NewLine
    }
    else {
        $statusMessage += "Device is NOT Intune Enrolled." + [Environment]::NewLine
    }

    # Determine migration status
    if ($dsregStatus.IsAzureADJoined -and -not $dsregStatus.IsHybridJoined -and $dsregStatus.IsMDMEnrolled) {
        $statusMessage += "No migration needed: Device is both Azure AD Joined and Intune Enrolled." + [Environment]::NewLine
    }
    else {
        $statusMessage += "Migration will now start: Device is either not Azure AD Joined or not Intune Enrolled." + [Environment]::NewLine
    }

    # Set the label text
    $label.Text = $statusMessage

    # Add the label to the form
    $form.Controls.Add($label)

    # Add an OK button to close the form
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Size = New-Object System.Drawing.Size(75, 30)
    $okButton.Location = New-Object System.Drawing.Point(150, 220)
    $okButton.Add_Click({ $form.Close() })

    # Add the button to the form
    $form.Controls.Add($okButton)

    # Bring the form to the front and show it
    $form.Activate()   # Ensure the form is active
    $form.ShowDialog()
}
