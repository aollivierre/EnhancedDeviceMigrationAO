function Show-MigrationInProgressForm {
    <#
    .SYNOPSIS
    Displays a migration in progress form.

    .DESCRIPTION
    The Show-MigrationInProgressForm function displays a form with a "Migration in Progress" message and an image to indicate that a migration process is ongoing. The form is displayed in full-screen mode and prevents user interaction with other windows.

    .PARAMETER ImagePath
    The path to the image file to be displayed on the form.

    .EXAMPLE
    $params = @{
        ImagePath = "C:\ProgramData\AADMigration\Files\MigrationInProgress.bmp"
    }
    Show-MigrationInProgressForm @params
    Displays the migration in progress form with the specified image.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Show-MigrationInProgressForm function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            if (-not (Test-Path -Path $ImagePath)) {
                Throw "Image file not found: $ImagePath"
            }

            [void][reflection.assembly]::LoadWithPartialName("System.Drawing")
            [void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
            $img = [System.Drawing.Image]::FromFile($ImagePath)

            [System.Windows.Forms.Application]::EnableVisualStyles()
            $form = New-Object Windows.Forms.Form
            $form.Text = "Migration in Progress"
            $form.WindowState = 'Maximized'
            $form.BackColor = "#000000"
            $form.TopMost = $true

            $pictureBox = New-Object Windows.Forms.PictureBox
            $pictureBox.Width = $img.Size.Width
            $pictureBox.Height = $img.Size.Height
            $pictureBox.Dock = "Fill"
            $pictureBox.SizeMode = "StretchImage"
            $pictureBox.Image = $img
            $form.Controls.Add($pictureBox)
            $form.Add_Shown({ $form.Activate() })
            $form.Show()
            Write-EnhancedLog -Message "Displayed migration in progress form." -Level "INFO"

            # Keep the form open
            # while ($form.Visible) {
            #     [System.Windows.Forms.Application]::DoEvents()
            # }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Show-MigrationInProgressForm function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Show-MigrationInProgressForm function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     ImagePath = "C:\ProgramData\AADMigration\Files\MigrationInProgress.bmp"
# }
# Show-MigrationInProgressForm @params
