function Get-GitHubPAT {
    [CmdletBinding()]
    param ()

    # Load necessary assemblies for Windows Forms
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Create a new form
    $form = New-Object system.windows.forms.Form
    $form.Text = "GitHub PAT Input"
    $form.Size = New-Object System.Drawing.Size(350,150)
    $form.StartPosition = "CenterScreen"

    # Create a label for instructions
    $label = New-Object system.windows.forms.Label
    $label.Text = "Enter your GitHub Personal Access Token (PAT):"
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10,10)
    $form.Controls.Add($label)

    # Create a textbox for the PAT input, with masking (password char)
    $textbox = New-Object system.windows.forms.TextBox
    $textbox.Size = New-Object System.Drawing.Size(300,20)
    $textbox.Location = New-Object System.Drawing.Point(10,40)
    $textbox.UseSystemPasswordChar = $true # Mask input
    $form.Controls.Add($textbox)

    # Create an OK button
    $okButton = New-Object system.windows.forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(190,70)
    $okButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $form.Controls.Add($okButton)

    # Create a Cancel button
    $cancelButton = New-Object system.windows.forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(100,70)
    $cancelButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })
    $form.Controls.Add($cancelButton)

    # Show the form
    $form.Topmost = $true
    $result = $form.ShowDialog()

    # Handle the result
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        # Convert the text input to a SecureString
        $SecurePAT = ConvertTo-SecureString $textbox.Text -AsPlainText -Force
        Write-Host "PAT securely captured."
        return $SecurePAT
    } else {
        Write-Host "Operation canceled."
        return $null
    }
}