# function Backup-DownloadsToOneDrive {
#     <#
#     .SYNOPSIS
#     Backs up the Downloads folder to OneDrive.

#     .DESCRIPTION
#     This function copies all files from the Downloads folder to a specified OneDrive backup directory using Robocopy. It verifies the existence of the OneDrive directory and uses logging for the backup process.

#     .PARAMETER DownloadsPath
#     The path to the Downloads folder.

#     .PARAMETER BackupFolderName
#     The name of the backup folder within OneDrive.

#     .PARAMETER Exclude
#     The directories or files to exclude from the copy operation. Default is ".git".

#     .PARAMETER RetryCount
#     The number of retries if a copy fails. Default is 2.

#     .PARAMETER WaitTime
#     The wait time between retries in seconds. Default is 5.

#     .PARAMETER RequiredSpaceGB
#     The required free space in gigabytes at the destination. Default is 10 GB.

#     .EXAMPLE
#     $params = @{
#         DownloadsPath = "$env:USERPROFILE\Downloads"
#         BackupFolderName = "DownloadsBackup"
#         Exclude = ".git"
#         RetryCount = 2
#         WaitTime = 5
#         RequiredSpaceGB = 10
#     }
#     Backup-DownloadsToOneDrive @params
#     #>

#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$DownloadsPath,

#         [Parameter(Mandatory = $true)]
#         [string]$BackupFolderName,

#         [Parameter(Mandatory = $false)]
#         [string[]]$Exclude = ".git",

#         [Parameter(Mandatory = $false)]
#         [int]$RetryCount = 2,

#         [Parameter(Mandatory = $false)]
#         [int]$WaitTime = 5,

#         [Parameter(Mandatory = $false)]
#         [int]$RequiredSpaceGB = 10
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Backup-DownloadsToOneDrive function" -Level "Notice"
#         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
#     }

#     Process {
#         try {
#             # Check for OneDrive directory existence
#             $oneDriveDirectory = (Get-ChildItem -Path "$env:USERPROFILE" -Filter "OneDrive - *" -Directory).FullName
#             if (-not $oneDriveDirectory) {
#                 Throw "OneDrive directory not found. Please ensure OneDrive is set up correctly."
#             }
#             Write-EnhancedLog -Message "OneDrive directory found: $oneDriveDirectory" -Level "INFO"

#             # Check if the Downloads directory exists
#             if (-not (Test-Path -Path $DownloadsPath)) {
#                 Throw "Downloads directory not found. Please ensure the path is correct."
#             }
#             Write-EnhancedLog -Message "Downloads directory found: $DownloadsPath" -Level "INFO"

#             # Define the destination path within the OneDrive directory
#             $backupPath = Join-Path -Path $oneDriveDirectory -ChildPath $BackupFolderName

#             # Check if destination path exists, if not create it
#             if (-not (Test-Path -Path $backupPath)) {
#                 New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
#                 Write-EnhancedLog -Message "Created backup directory at: $backupPath" -Level "INFO"
#             }

#             # Use splatting for function parameters
#             $params = @{
#                 Source          = $DownloadsPath
#                 Destination     = $backupPath
#                 FilePattern     = '*'
#                 Exclude         = $Exclude
#                 RetryCount      = $RetryCount
#                 WaitTime        = $WaitTime
#                 RequiredSpaceGB = $RequiredSpaceGB
#             }

#             # Execute the function with splatting
#             Copy-FilesWithRobocopy @params

#             Write-EnhancedLog -Message "Backup of Downloads to OneDrive completed successfully." -Level "INFO"
#         }
#         catch {
#             Write-EnhancedLog -Message "An error occurred in Backup-DownloadsToOneDrive function: $($_.Exception.Message)" -Level "ERROR"
#             Handle-Error -ErrorRecord $_
#         }
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Backup-DownloadsToOneDrive function" -Level "Notice"
#     }
# }

# # Example usage
# # $params = @{
# #     DownloadsPath = "$env:USERPROFILE\Downloads"
# #     BackupFolderName = "DownloadsBackup"
# #     Exclude = ".git"
# #     RetryCount = 2
# #     WaitTime = 5
# #     RequiredSpaceGB = 10
# # }
# # Backup-DownloadsToOneDrive @params
