function Backup-ChromeBookmarksToOneDrive {
    <#
    .SYNOPSIS
    Backs up the Chrome bookmarks to OneDrive.

    .DESCRIPTION
    This function copies the Chrome bookmarks file from the Chrome user profile to a specified OneDrive backup directory using Robocopy. It verifies the existence of the OneDrive directory and uses logging for the backup process.

    .PARAMETER ChromeProfilePath
    The path to the Chrome user profile directory.

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
        ChromeProfilePath = "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default"
        BackupFolderName = "ChromeBackup"
        Exclude = ".git"
        RetryCount = 2
        WaitTime = 5
        RequiredSpaceGB = 10
    }
    Backup-ChromeBookmarksToOneDrive @params
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ChromeProfilePath,

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
        Write-EnhancedLog -Message "Starting Backup-ChromeBookmarksToOneDrive function" -Level "Notice"
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

            # Check if the Chrome profile directory exists
            if (-not (Test-Path -Path $ChromeProfilePath)) {
                Write-EnhancedLog -Message "Chrome profile directory not found. It seems Google Chrome is not installed or used." -Level "Warning"
                return
            }
            Write-EnhancedLog -Message "Chrome profile directory found: $ChromeProfilePath" -Level "INFO"

            # Define the destination path within the OneDrive directory
            $backupPath = Join-Path -Path $oneDriveDirectory -ChildPath $BackupFolderName

            # Check if destination path exists, if not create it
            if (-not (Test-Path -Path $backupPath)) {
                New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
                Write-EnhancedLog -Message "Created backup directory at: $backupPath" -Level "INFO"
            }

            # Temporary directory for copying the specific file
            $tempDir = "C:\Users\Admin-Abdullah\AppData\Local\Temp\ChromeTemp"

            # Ensure the temporary directory exists
            if (-not (Test-Path -Path $tempDir)) {
                New-Item -ItemType Directory -Path $tempDir
            }

            # Files to back up
            $filesToBackup = @("Bookmarks")

            foreach ($file in $filesToBackup) {
                $sourceFilePath = $ChromeProfilePath # Robocopy uses directory paths
                $destinationFilePath = $backupPath # Robocopy destination directory

                # Check if the source file exists before attempting to copy
                if (Test-Path -Path (Join-Path -Path $sourceFilePath -ChildPath $file)) {
                    try {
                        # Copy the Bookmarks file to the temporary directory
                        Copy-Item -Path (Join-Path -Path $sourceFilePath -ChildPath $file) -Destination $tempDir

                        # Use splatting for function parameters
                        $params = @{
                            Source          = $tempDir
                            Destination     = $destinationFilePath
                            FilePattern     = $file
                            Exclude         = $Exclude
                            RetryCount      = $RetryCount
                            WaitTime        = $WaitTime
                            RequiredSpaceGB = $RequiredSpaceGB
                        }
                        
                        # Execute the function with splatting
                        Copy-FilesWithRobocopy @params

                        Write-EnhancedLog -Message "Successfully backed up '$file' to '$destinationFilePath'." -Level "INFO"

                        # Remove the temporary directory
                        Remove-Item -Path $tempDir -Recurse -Force
                    }
                    catch {
                        Write-EnhancedLog -Message "An error occurred while backing up '$file': $_" -Level "ERROR"
                        Handle-Error -ErrorRecord $_
                    }
                }
                else {
                    Write-EnhancedLog -Message "'$file' does not exist in the source directory and will not be backed up." -Level "Warning"
                }
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Backup-ChromeBookmarksToOneDrive function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Backup-ChromeBookmarksToOneDrive function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     ChromeProfilePath = "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default"
#     BackupFolderName = "ChromeBackup"
#     Exclude = ".git"
#     RetryCount = 2
#     WaitTime = 5
#     RequiredSpaceGB = 10
# }
# Backup-ChromeBookmarksToOneDrive @params
