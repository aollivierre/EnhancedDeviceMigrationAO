function Prepare-AADMigration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MigrationPath,

        [Parameter(Mandatory = $true)]
        [string]$PSScriptbase,

        [Parameter(Mandatory = $true)]
        [string]$ConfigBaseDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ConfigFileName,

        [Parameter(Mandatory = $true)]
        [string]$TenantID,

        [Parameter(Mandatory = $true)]
        [bool]$OneDriveKFM,

        [Parameter(Mandatory = $true)]
        [bool]$InstallOneDrive
    )

    Begin {
        Write-EnhancedLog -Message "Starting Prepare-AADMigration function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Ensure the target directory exists
            if (-not (Test-Path -Path $MigrationPath)) {
                New-Item -Path $MigrationPath -ItemType Directory -Force | Out-Null
            }

            # Copy the entire content of $PSScriptRoot to $MigrationPath
      
            # Define the source and destination paths
            $sourcePath1 = $PSScriptbase
            # $sourcePath2 = "C:\code\modulesv2"
            $destinationPath1 = $MigrationPath
            # $destinationPath2 = "$MigrationPath\modulesv2"

            # Copy files from $PSScriptRoot using the Copy-FilesToPath function
            # Copy-FilesToPath -SourcePath $sourcePath1 -DestinationPath $destinationPath1

            Stop-ProcessesUsingOneDriveLib -OneDriveLibPath "C:\ProgramData\AADMigration\Files\OneDriveLib.dll"

            # $DBG

            Remove-ScheduledTaskFilesWithLogging -Path $destinationPath1

            # Copy-FilesToPathWithKill -SourcePath $sourcePath1 -DestinationPath $destinationPath1

            # Ensure the destination directory exists
            if (Test-Path -Path $destinationPath1) {
                Write-EnhancedLog -Message "Destination directory already exists. Removing: $destinationPath1" -Level "WARNING"
                Remove-Item -Path $destinationPath1 -Recurse -Force
                Write-EnhancedLog -Message "Destination directory removed: $destinationPath1" -Level "INFO"
            }

            # Create a new destination directory
            New-Item -Path $destinationPath1 -ItemType Directory | Out-Null
            Write-EnhancedLog -Message "New destination directory created: $destinationPath1" -Level "INFO"


            $params = @{
                Source          = $sourcePath1
                Destination     = $destinationPath1
                Exclude         = ".git"
                RetryCount      = 2
                WaitTime        = 5
                RequiredSpaceGB = 10
            }


            # Execute the function with splatting
            Copy-FilesWithRobocopy @params

            $DBG


            # Verify the copy operation for $PSScriptRoot
            Verify-CopyOperation -SourcePath $sourcePath1 -DestinationPath $destinationPath1





            ####################################################################################

            # Copy files from C:\code\modules using the Copy-FilesToPath function
            # Copy-FilesToPath -SourcePath $sourcePath2 -DestinationPath $destinationPath2

            # Copy-FilesToPathWithKill -SourcePath $sourcePath2 -DestinationPath $destinationPath2


            # Ensure the destination directory exists
            # if (-not (Test-Path -Path $destinationPath2)) {
            #     New-Item -Path $destinationPath2 -ItemType Directory | Out-Null
            # }


            # $params = @{
            #     Source          = $sourcePath2
            #     Destination     = $destinationPath2
            #     Exclude         = ".git"
            #     RetryCount      = 2
            #     WaitTime        = 5
            #     RequiredSpaceGB = 10
            # }

            # Execute the function with splatting
            # Copy-FilesWithRobocopy @params




            # Verify the copy operation for C:\code\modulesv2
            # Verify-CopyOperation -SourcePath $sourcePath2 -DestinationPath $destinationPath2


            # $DBG

            # Write-EnhancedLog -Message "Copied content from $PSScriptRoot to $MigrationPath" -Level "INFO"

            # $DBG

            # Import migration configuration
            $MigrationConfig = Import-LocalizedData -BaseDirectory $ConfigBaseDirectory -FileName $ConfigFileName
            $TenantID = $MigrationConfig.TenantID
            $OneDriveKFM = $MigrationConfig.UseOneDriveKFM
            $InstallOneDrive = $MigrationConfig.InstallOneDrive

            # $DBG

            # Set OneDrive KFM settings if required
            if ($OneDriveKFM) {

                # $TenantID = "YourTenantID"
                $RegistrySettings = @(
                    @{
                        RegValName = "AllowTenantList"
                        RegValType = "STRING"
                        RegValData = $TenantID
                    },
                    @{
                        RegValName = "SilentAccountConfig"
                        RegValType = "DWORD"
                        RegValData = "1"
                    },
                    @{
                        RegValName = "KFMOptInWithWizard"
                        RegValType = "STRING"
                        RegValData = $TenantID
                    },
                    @{
                        RegValName = "KFMSilentOptIn"
                        RegValType = "STRING"
                        RegValData = $TenantID
                    },
                    @{
                        RegValName = "KFMSilentOptInDesktop"
                        RegValType = "DWORD"
                        RegValData = "1"
                    },
                    @{
                        RegValName = "KFMSilentOptInDocuments"
                        RegValType = "DWORD"
                        RegValData = "1"
                    },
                    @{
                        RegValName = "KFMSilentOptInPictures"
                        RegValType = "DWORD"
                        RegValData = "1"
                    }
                )
                
                $SetODKFMRegistrySettingsParams = @{
                    TenantID         = $TenantID
                    RegKeyPath       = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
                    RegistrySettings = $RegistrySettings
                }
                
                Set-ODKFMRegistrySettings @SetODKFMRegistrySettingsParams
                


                $DBG

                Unregister-ScheduledTaskWithLogging -TaskName "AADM Get OneDrive Sync Status"

                # # Example usage with splatting
                # $CreateOneDriveSyncStatusTaskParams = @{
                #     TaskPath               = "AAD Migration"
                #     TaskName               = "AADM Get OneDrive Sync Status"
                #     ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
                #     ScriptName             = "Check-OneDriveSyncStatus.ps1"
                #     TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
                #     TaskRepetitionDuration = "P1D"
                #     TaskRepetitionInterval = "PT30M"
                #     TaskPrincipalGroupId   = "BUILTIN\Users"
                #     PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                #     TaskDescription        = "Get current OneDrive Sync Status and write to event log"
                # }

                # Create-OneDriveSyncStatusTask @CreateOneDriveSyncStatusTaskParams

                # $DBG

            }

            # Install OneDrive if required
            if ($InstallOneDrive) {
                

                # Example usage
                $installParams = @{
                    MigrationPath            = "C:\ProgramData\AADMigration"
                    SoftwareName             = "OneDrive"
                    SetupUri                 = "https://go.microsoft.com/fwlink/?linkid=844652"
                    SetupFile                = "OneDriveSetup.exe"
                    RegKey                   = "HKLM:\SOFTWARE\Microsoft\OneDrive"
                    MinVersion               = [version]"24.146.0721.0003"
                    ExePath                  = "C:\Program Files\Microsoft OneDrive\OneDrive.exe"
                    ScheduledTaskName        = "OneDriveRemediation"
                    ScheduledTaskDescription = "Restart OneDrive to kick off KFM sync"
                    SetupArgumentList        = "/allusers"
                    KFM                      = $true
                    TimestampPrefix          = "OneDriveSetup_"
                }
                
                Install-Software @installParams


                $DBG



               
            }

            # # Example usage with splatting
            # $CreateOneDriveSyncStatusTaskParams = @{
            #     TaskPath               = "AAD Migration"
            #     TaskName               = "AADM Get OneDrive Sync Status"
            #     ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
            #     ScriptName             = "Check-OneDriveSyncStatus.ps1"
            #     TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
            #     TaskRepetitionDuration = "P1D"
            #     TaskRepetitionInterval = "PT30M"
            #     TaskPrincipalGroupId   = "BUILTIN\Users"
            #     PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            #     TaskDescription        = "Get current OneDrive Sync Status and write to event log"
            # }

            # Create-OneDriveSyncStatusTask @CreateOneDriveSyncStatusTaskParams


            $CreateOneDriveSyncStatusTaskParams = @{
                TaskPath               = "AAD Migration"
                TaskName               = "AADM Get OneDrive Sync Util Status"
                ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
                ScriptName             = "Check-ODSyncUtilStatus.ps1"
                TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
                TaskRepetitionDuration = "P1D"
                TaskRepetitionInterval = "PT30M"
                TaskPrincipalGroupId   = "BUILTIN\Users"
                PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                TaskDescription        = "Get current OneDrive Sync Status and write to event log"
            }

            Create-OneDriveSyncUtilStatusTask @CreateOneDriveSyncStatusTaskParams


            # Should we check OneDrive Sync before OR after the prep ? Currently this is being called after the Prep and I wonder if we should call it BEFORE the Prep instead
            # Check-OneDriveSyncStatus -OneDriveLibPath "C:\ProgramData\AADMigration\Files\OneDriveLib.dll"

            # Example usage
            # Define parameters using a hashtable
            # $taskParams = @{
            #     TaskPath = "\AAD Migration"
            #     TaskName = "AADM Get OneDrive Sync Status"
            # }

            # # Trigger OneDrive Sync Status Scheduled Task
            # Trigger-ScheduledTask @taskParams


            $taskParams = @{
                TaskPath = "\AAD Migration"
                TaskName = "AADM Get OneDrive Sync Util Status"
            }

            # Trigger OneDrive Sync Status Scheduled Task
            Trigger-ScheduledTask @taskParams

            # # Example usage with splatting
            # $AnalyzeParams = @{
            #     LogFolder      = "C:\ProgramData\AADMigration\logs"
            #     StatusFileName = "OneDriveSyncStatus.json"
            # }

            # Analyze-OneDriveSyncStatus @AnalyzeParams

            # # # Example usage
            $AnalyzeOneDriveSyncUtilStatusParams = @{
                LogFolder     = "C:\ProgramData\AADMigration\logs"
                StatusFileName = "ODSyncUtilStatus.json"
            }
            Analyze-OneDriveSyncUtilStatus @AnalyzeOneDriveSyncUtilStatusParams



            #Todo now we have OneDrive installed and running we need to actually start using our OneDrive for Business location on the local machine to copy user specific files into it as part of our On-prem AD to Entra ID migration prep so we need to copy the following PR4B projects from before

            # 1- copy Outlook Signatures
            # 2- copy Downloads folders
            # any other user specific files


            $CreateUserFileBackupTaskParams = @{
                TaskPath               = "AAD Migration"
                TaskName               = "User File Backup to OneDrive"
                BackupScriptPath       = "C:\ProgramData\AADMigration\Scripts\BackupUserFiles.ps1"
                TaskRepetitionDuration = "P1D"  # 1 day
                TaskRepetitionInterval = "PT1H"  # 1 hour
                TaskPrincipalGroupId   = "BUILTIN\USERS"
                PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                TaskDescription        = "Backup user files to a designated location"
            }

            Create-UserFileBackupTask @CreateUserFileBackupTaskParams


            $taskParams = @{
                TaskPath = "\AAD Migration"
                TaskName = "User File Backup to OneDrive"
            }

            # Call the function with splatting
            Trigger-ScheduledTask @taskParams

            # # Example usage with splatting
            $AnalyzeParams = @{
                LogFolder      = "C:\ProgramData\AADMigration\logs"
                StatusFileName = "UserFilesBackupStatus.json"
            }

            Analyze-CopyOperationStatus @AnalyzeParams



            # # Example usage
            # $BackupChromeBookmarksToOneDriveParams = @{
            #     ChromeProfilePath = "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default"
            #     BackupFolderName  = "ChromeBackup"
            #     Exclude           = ".git"
            #     RetryCount        = 2
            #     WaitTime          = 5
            #     RequiredSpaceGB   = 10
            # }
            # Backup-ChromeBookmarksToOneDrive @BackupChromeBookmarksToOneDriveParams


            # $BackupOutlookSignaturesToOneDrive = @{
            #     SignaturePath    = "$env:USERPROFILE\AppData\Roaming\Microsoft\Signatures"
            #     BackupFolderName = "OutlookSignatures"
            #     Exclude          = ".git"
            #     RetryCount       = 2
            #     WaitTime         = 5
            #     RequiredSpaceGB  = 10
            # }
            # Backup-OutlookSignaturesToOneDrive @BackupOutlookSignaturesToOneDrive


            # $BackupDownloadsToOneDriveParams = @{
            #     DownloadsPath    = "$env:USERPROFILE\Downloads"
            #     BackupFolderName = "DownloadsBackup"
            #     Exclude          = ".git"
            #     RetryCount       = 2
            #     WaitTime         = 5
            #     RequiredSpaceGB  = 10
            # }
            # Backup-DownloadsToOneDrive @BackupDownloadsToOneDriveParams

        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Prepare-AADMigration: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Prepare-AADMigration function" -Level "Notice"
    }
}

# # Define parameters
# $PrepareAADMigrationParams = @{
#     MigrationPath       = "C:\ProgramData\AADMigration"
#     PSScriptRoot        = "C:\SourcePath"
#     ConfigBaseDirectory = "C:\ConfigDirectory\Scripts"
#     ConfigFileName      = "MigrationConfig.psd1"
#     TenantID            = "YourTenantID"
#     OneDriveKFM         = $true
#     InstallOneDrive     = $true
# }

# # Example usage with splatting
# Prepare-AADMigration @PrepareAADMigrationParams