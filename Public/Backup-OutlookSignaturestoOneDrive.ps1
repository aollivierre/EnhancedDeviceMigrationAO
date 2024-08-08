function Backup-OutlookSignaturesToOneDrive {
    <#
    .SYNOPSIS
    Backs up the Outlook Signatures folder to OneDrive.

    .DESCRIPTION
    This function copies all files from the Outlook Signatures folder to a specified OneDrive backup directory using Robocopy. It verifies the existence of the OneDrive directory and uses logging for the backup process.

    .PARAMETER SignaturePath
    The path to the Outlook Signatures folder.

    .PARAMETER BackupFolderName
    The name of the backup folder within OneDrive.

    .PARAMETER Exclude
    The directories or files to exclude from the copy operation. Default is ".git".

    .PARAMETER RetryCount
    The number of retries if a copy fails. Default is 2.

    .PARAMETER WaitTime
    The wait time between retries in seconds. Default is 5.

    .PARAMETER RequiredSpaceGB
    The required free space in gigabytes at the destination. Default is 10 GB.

    .EXAMPLE
    $params = @{
        SignaturePath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Signatures"
        BackupFolderName = "OutlookSignatures"
        Exclude = ".git"
        RetryCount = 2
        WaitTime = 5
        RequiredSpaceGB = 10
    }
    Backup-OutlookSignaturesToOneDrive @params
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SignaturePath,

        [Parameter(Mandatory = $true)]
        [string]$BackupFolderName,

        [Parameter(Mandatory = $false)]
        [string[]]$Exclude = ".git",

        [Parameter(Mandatory = $false)]
        [int]$RetryCount = 2,

        [Parameter(Mandatory = $false)]
        [int]$WaitTime = 5,

        [Parameter(Mandatory = $false)]
        [int]$RequiredSpaceGB = 10
    )

    Begin {
        Write-EnhancedLog -Message "Starting Backup-OutlookSignaturesToOneDrive function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Check for OneDrive directory existence
            $oneDriveDirectory = (Get-ChildItem -Path "$env:USERPROFILE" -Filter "OneDrive - *" -Directory).FullName
            if (-not $oneDriveDirectory) {
                Throw "OneDrive directory not found. Please ensure OneDrive is set up correctly."
            }
            Write-EnhancedLog -Message "OneDrive directory found: $oneDriveDirectory" -Level "INFO"

            # Check if the Outlook Signatures directory exists
            if (-not (Test-Path -Path $SignaturePath)) {
                Write-EnhancedLog -Message "Outlook Signatures directory not found. It seems Outlook is not set up." -Level "Warning"
                return
            }
            Write-EnhancedLog -Message "Outlook Signatures directory found: $SignaturePath" -Level "INFO"

            # Define the destination path within the OneDrive directory
            $backupPath = Join-Path -Path $oneDriveDirectory -ChildPath $BackupFolderName

            # Check if destination path exists, if not create it
            if (-not (Test-Path -Path $backupPath)) {
                New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
                Write-EnhancedLog -Message "Created backup directory at: $backupPath" -Level "INFO"
            }

            # Use splatting for function parameters
            $params = @{
                Source          = $SignaturePath
                Destination     = $backupPath
                FilePattern     = '*'
                Exclude         = $Exclude
                RetryCount      = $RetryCount
                WaitTime        = $WaitTime
                RequiredSpaceGB = $RequiredSpaceGB
            }

            # Execute the function with splatting
            Copy-FilesWithRobocopy @params

            Write-EnhancedLog -Message "Backup of Outlook Signatures to OneDrive completed successfully." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Backup-OutlookSignaturesToOneDrive function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Backup-OutlookSignaturesToOneDrive function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     SignaturePath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Signatures"
#     BackupFolderName = "OutlookSignatures"
#     Exclude = ".git"
#     RetryCount = 2
#     WaitTime = 5
#     RequiredSpaceGB = 10
# }
# Backup-OutlookSignaturesToOneDrive @params
