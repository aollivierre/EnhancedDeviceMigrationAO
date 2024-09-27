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
                Write-EnhancedLog -Message "New destination directory created: $MigrationPath" -Level "INFO"
            }

            # Copy the entire content of $PSScriptRoot to $MigrationPath

            Stop-ProcessesUsingOneDriveLib -OneDriveLibPath "C:\ProgramData\AADMigration\Files\OneDriveLib.dll"

            # $DBG

            # Remove the ADD migration 
            Remove-ScheduledTaskFilesWithLogging -Path $MigrationPath

            # Copy-FilesToPathWithKill -SourcePath $sourcePath1 -DestinationPath $destinationPath1

            # Ensure the destination directory exists
            # if (Test-Path -Path $MigrationPath) {
            #     Write-EnhancedLog -Message "Destination directory already exists. Removing: $MigrationPath" -Level "WARNING"
            #     Remove-Item -Path $MigrationPath -Recurse -Force
            #     Write-EnhancedLog -Message "Destination directory removed: $MigrationPath" -Level "INFO"
            # }

            # Create a new destination directory
            # New-Item -Path $MigrationPath -ItemType Directory | Out-Null


            if (-not (Test-Path -Path $MigrationPath)) {
                New-Item -Path $MigrationPath -ItemType Directory -Force | Out-Null
                Write-EnhancedLog -Message "New destination directory created: $MigrationPath" -Level "INFO"
            }
            


            $params = @{
                Source          = $PSScriptbase
                Destination     = $MigrationPath
                Exclude         = ".git"
                RetryCount      = 2
                WaitTime        = 5
                RequiredSpaceGB = 10
            }


            # Execute the function with splatting
            Copy-FilesWithRobocopy @params

            # Verify the copy operation for $PSScriptRoot
            Verify-CopyOperation -SourcePath $PSScriptbase -DestinationPath $MigrationPath
            ####################################################################################
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
            }

            # # Example usage with splatting
            $CreateOneDriveSyncUtilStatusTask = @{
                TaskPath               = "AAD Migration"
                TaskName               = "AADM Get OneDrive Sync Util Status"
                ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
                ScriptName             = "Check-ODSyncUtilStatus.Task.ps1"
                TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
                TaskRepetitionDuration = "P1D"
                TaskRepetitionInterval = "PT30M"
                TaskPrincipalGroupId   = "BUILTIN\Users"
                PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                TaskDescription        = "AADM Get OneDrive Sync Util Status"
                AtLogOn                = $true
            }

            Create-OneDriveSyncUtilStatusTask @CreateOneDriveSyncUtilStatusTask


            $RemoveExistingStatusFilesParams = @{
                LogFolder      = "logs"
                StatusFileName = "ODSyncUtilStatus.json"
        
            }
            # Remove existing status files
            Remove-ExistingStatusFiles @RemoveExistingStatusFilesParams


            $taskParams = @{
                TaskPath = "\AAD Migration"
                TaskName = "AADM Get OneDrive Sync Util Status"
            }

            # Trigger OneDrive Sync Status Scheduled Task
            Trigger-ScheduledTask @taskParams

            # Example usage with try-catch mechanism and Write-EnhancedLog
            $AnalyzeOneDriveSyncUtilStatusParams = @{
                LogFolder      = "logs"
                StatusFileName = "ODSyncUtilStatus.json"
                MaxRetries     = 5
                RetryInterval  = 10
            }

            try {
                $result = Analyze-OneDriveSyncUtilStatus @AnalyzeOneDriveSyncUtilStatusParams

                # Example decision-making based on the result
                if ($result.Status -eq "Healthy") {
                    Write-EnhancedLog -Message "OneDrive is healthy, no further action required." -Level "INFO"
                }
                elseif ($result.Status -eq "InProgress") {
                    Write-EnhancedLog -Message "OneDrive is syncing, please wait..." -Level "INFO"
                }
                elseif ($result.Status -eq "Failed") {
                    Write-EnhancedLog -Message "OneDrive has encountered an error, please investigate." -Level "WARNING"
                }
                else {
                    Write-EnhancedLog -Message "OneDrive status is unknown, further analysis required." -Level "NOTICE"
                }
            }
            catch {
                Write-EnhancedLog -Message "An error occurred while analyzing OneDrive status: $($_.Exception.Message)" -Level "ERROR"
                Write-EnhancedLog -Message "Please check if you are logged in to OneDrive and try again." -Level "ERROR"
                Handle-Error -ErrorRecord $_
    
                # Throw to halt the entire script
                throw $_
            }


            #Todo now we have OneDrive installed and running we need to actually start using our OneDrive for Business location on the local machine to copy user specific files into it as part of our On-prem AD to Entra ID migration prep so we need to copy the following PR4B projects from before

            # 1- copy Outlook Signatures
            # 2- copy Downloads folders
            # any other user specific files

            $CreateUserFileBackupTaskParams = @{
                TaskPath               = "AAD Migration"
                TaskName               = "User File Backup to OneDrive"
                ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
                ScriptName             = "BackupUserFiles.Task.ps1"
                TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
                TaskRepetitionDuration = "P1D"
                TaskRepetitionInterval = "PT30M"
                TaskPrincipalGroupId   = "BUILTIN\Users"
                PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                TaskDescription        = "User File Backup to OneDrive"
                AtLogOn                = $true
            }
            
            Create-UserFileBackupTask @CreateUserFileBackupTaskParams


            $RemoveExistingStatusFilesParams = @{
                LogFolder      = "logs"
                StatusFileName = "UserFilesBackupStatus.json"
            }
            # Remove existing status files
            Remove-ExistingStatusFiles @RemoveExistingStatusFilesParams


            $TriggerScheduledTaskParams = @{
                TaskPath = "\AAD Migration"
                TaskName = "User File Backup to OneDrive"
            }

            # Call the function with splatting
            Trigger-ScheduledTask @TriggerScheduledTaskParams

            # Define the parameters for splatting
            $AnalyzeParams = @{
                LogFolder      = "logs"
                StatusFileName = "UserFilesBackupStatus.json"
                MaxRetries     = 5
                RetryInterval  = 10
            }

            # Call the Analyze-CopyOperationStatus function using splatting
            Analyze-CopyOperationStatus @AnalyzeParams

        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Prepare-AADMigration: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
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