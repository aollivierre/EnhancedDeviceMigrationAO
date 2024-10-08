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

            # # # Example usage with splatting
            # $CreateOneDriveSyncUtilStatusTask = @{
            #     TaskPath               = "AAD Migration"
            #     TaskName               = "AADM Get OneDrive Sync Util Status"
            #     ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
            #     ScriptName             = "Check-ODSyncUtilStatus.Task.ps1"
            #     TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
            #     TaskRepetitionDuration = "P1D"
            #     TaskRepetitionInterval = "PT30M"
            #     TaskPrincipalGroupId   = "BUILTIN\Users"
            #     PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            #     TaskDescription        = "AADM Get OneDrive Sync Util Status"
            #     AtLogOn                = $true
            # }

            # Create-OneDriveSyncUtilStatusTask @CreateOneDriveSyncUtilStatusTask



            # $CreateOneDriveSyncUtilStatusTask = @{
            #     TaskPath               = "AAD Migration"
            #     TaskName               = "AADM Get OneDrive Sync Util Status"
            #     ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
            #     ScriptName             = "Check-ODSyncUtilStatus.Task.ps1"
            #     TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
            #     TaskRepetitionDuration = "P1D"
            #     TaskRepetitionInterval = "PT30M"
            #     PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            #     TaskDescription        = "Get current OneDrive Sync Status and write to event log"
            #     AtLogOn                = $true
            #     # UseCurrentUser         = $true  # Specify to use the current user
            #     TaskPrincipalGroupId   = "BUILTIN\Users"
            # }
            
            # Create-OneDriveSyncUtilStatusTask @CreateOneDriveSyncUtilStatusTask
            


            # $NewScheduledTaskUtilityTaskParams = @{
            #     TaskPath             = "AAD Migration"
            #     TaskName             = "AADM Get OneDrive Sync Util Status"
            #     ScriptDirectory      = "C:\ProgramData\AADMigration\Scripts"
            #     ScriptName           = "Check-ODSyncUtilStatus.Task.ps1"
            #     TaskArguments        = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
            #     # TaskRepetitionDuration = "P1D"
            #     # TaskRepetitionInterval = "PT30M"
            #     PowerShellPath       = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            #     TaskDescription      = "Get current OneDrive Sync Status and write to event log"
            #     AtLogOn              = $true
            #     # UseCurrentUser         = $true
            #     TaskPrincipalGroupId = "BUILTIN\Users"
            #     HideWithVBS          = $true
            #     # EnableRepetition       = $true
            #     VbsFileName          = "run-ps-hidden.vbs"  # Optional: Custom VBS file name
            # }
            
            # New-ScheduledTaskUtility @NewScheduledTaskUtilityTaskParams


            # $NewScheduledTaskUtilityTaskParams = @{

            #     ### General Task Settings ###
            #     TaskPath             = "AAD Migration"  # The path to the task in the Task Scheduler (like a folder name).
            #                                             # Customize this to organize your tasks under a specific folder in Task Scheduler.
            
            #     TaskName             = "User File Backup to OneDrive"  # The name of the task.
            #                                                            # Customize it based on what the task does (e.g., "BackupUserFiles").
            
            #     TaskDescription      = "User File Backup to OneDrive"  # A short description of what the task does.
            #                                                            # Helpful for future reference when viewing tasks in Task Scheduler.
            
            #     ### Script Details (PowerShell or Other Script) ###
            #     ScriptDirectory      = "C:\ProgramData\AADMigration\Scripts"  # The directory where the PowerShell script is located.
            #                                                                   # Customize this to point to where your script is stored.
            
            #     ScriptName           = "BackupUserFiles.Task.ps1"  # The name of the PowerShell script to run.
            #                                                        # This should match the file name of your PowerShell script.
            
            #     # NOTE: PowerShellPath and TaskArguments are only used if HideWithVBS is NOT set to true.
            #     # PowerShellPath       = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            #                           # Path to the PowerShell executable. 
            #                           # Only used when `HideWithVBS` is set to `$false`. 
            #                           # If `HideWithVBS` is `$true`, this is ignored, and `wscript.exe` will run the task hidden.
            
            #     # TaskArguments        = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
            #                           # Arguments to pass when running the PowerShell script.
            #                           # Only used when `HideWithVBS` is set to `$false`. 
            #                           # When `HideWithVBS` is `$true`, a VBScript handles the execution of PowerShell.
            
            #     ### Task Trigger (When to Run the Task) ###
            #     AtLogOn              = $true  # Triggers the task to run when the user logs on.
            #                                   # Set this to `$true` if you want the task to run at user logon.
            #                                   # If you want to schedule it for another trigger (like daily or weekly), you can change this.
            
            #     ### Task Principal (Who the Task Runs As) ###
            #     # UseCurrentUser         = $true  # Uncomment this if you want the task to run as the current logged-in user.
            #                                       # This is useful if the task needs user-level permissions.
            #                                       # Leave this commented out if you're specifying a group or user in TaskPrincipalGroupId.
                
            #     TaskPrincipalGroupId = "BUILTIN\Users"  # Specify the user group under which the task will run.
            #                                             # Use this if you want the task to run under a specific group (e.g., "Administrators" or "Users").
            #                                             # Leave this as is if you don’t need to specify a custom group and are using UseCurrentUser.
            
            #     ### VBS Hidden Execution (Optional) ###
            #     HideWithVBS          = $true  # Set to `$true` if you want the task to run using a hidden VBScript (prevents a visible PowerShell window).
            #                                   # When `$true`, the task will use `wscript.exe` to run the task invisibly via VBScript, 
            #                                   # and `PowerShellPath` and `TaskArguments` will be ignored.
                
            #     VbsFileName          = "run-ps-hidden.vbs"  # The name of the VBScript file that will be created if `HideWithVBS` is enabled.
            #                                                 # You can customize this name if needed, but the default should work for most cases.
                
            #     ### Task Repetition (Optional) ###
            #     # EnableRepetition       = $true  # Uncomment this if you want the task to repeat at regular intervals (e.g., every 30 minutes).
            #                                       # Leave it commented out if you don't need the task to repeat.
            
            #     # TaskRepetitionDuration = "P1D"  # The total duration for which the task should repeat (e.g., "P1D" for 1 day).
            #                                      # Only relevant if `EnableRepetition` is set to `$true`. You can customize this based on your needs.
            
            #     # TaskRepetitionInterval = "PT30M"  # The interval between repetitions (e.g., "PT30M" for 30 minutes).
            #                                        # Only relevant if `EnableRepetition` is set to `$true`. Customize it for different intervals (e.g., "PT1H" for hourly).
            
            # }
            
            # # Execute the utility function to create the scheduled task using the parameters defined above
            # New-ScheduledTaskUtility @NewScheduledTaskUtilityTaskParams
            




            $NewScheduledTaskUtilityTaskParams = @{
                ### General Task Settings ###
                TaskPath             = "AAD Migration"
                TaskName             = "AADM Get OneDrive Sync Util Status"
                TaskDescription      = "Get current OneDrive Sync Status and write to event log"
            
                ### Script Details ###
                ScriptDirectory      = "C:\ProgramData\AADMigration\Scripts"
                ScriptName           = "Check-ODSyncUtilStatus.Task.ps1"
            
                ### Task Trigger ###
                AtLogOn              = $true
            
                ### Task Principal ###
                TaskPrincipalGroupId = "BUILTIN\Users"
            
                ### VBS Hidden Execution ###
                HideWithVBS          = $true
                VbsFileName          = "run-ps-hidden.vbs"
            }
            
            # Execute the utility function to create the scheduled task using the parameters defined above
            New-ScheduledTaskUtility @NewScheduledTaskUtilityTaskParams



            # Wait-Debugger



            $RemoveExistingStatusFilesParams = @{
                LogFolder      = "logs"
                StatusFileName = "ODSyncUtilStatus.json"
        
            }
            # Remove existing status files
            Remove-ExistingStatusFiles @RemoveExistingStatusFilesParams


            $taskParams = @{
                TaskPath = "AAD Migration"
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


            # $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            # Write-Host "Current User: $currentUser"

            # $CreateUserFileBackupTaskParams = @{
            #     TaskPath               = "AAD Migration"
            #     TaskName               = "User File Backup to OneDrive"
            #     ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
            #     ScriptName             = "BackupUserFiles.Task.ps1"
            #     TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
            #     TaskRepetitionDuration = "P1D"
            #     TaskRepetitionInterval = "PT30M"
            #     TaskPrincipalGroupId   = "BUILTIN\Users"
            #     PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            #     TaskDescription        = "User File Backup to OneDrive"
            #     AtLogOn                = $true
            # }
            
            # Create-UserFileBackupTask @CreateUserFileBackupTaskParams



            # $CreateUserFileBackupTaskParams = @{
            #     TaskPath               = "AAD Migration"
            #     TaskName               = "User File Backup to OneDrive"
            #     ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
            #     ScriptName             = "BackupUserFiles.Task.ps1"
            #     TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
            #     TaskRepetitionDuration = "P1D"
            #     TaskRepetitionInterval = "PT30M"
            #     PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            #     TaskDescription        = "User File Backup to OneDrive"
            #     AtLogOn                = $true
            #     # UseCurrentUser         = $true  # Switch to use the current user

            #     TaskPrincipalGroupId   = "BUILTIN\Users"

            # }
            
            # Create-UserFileBackupTask @CreateUserFileBackupTaskParams
            



            # $NewScheduledTaskUtilityTaskParams = @{
            #     TaskPath             = "AAD Migration"
            #     TaskName             = "User File Backup to OneDrive"
            #     ScriptDirectory      = "C:\ProgramData\AADMigration\Scripts"
            #     ScriptName           = "BackupUserFiles.Task.ps1"
            #     TaskArguments        = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
            #     # TaskRepetitionDuration = "P1D"
            #     # TaskRepetitionInterval = "PT30M"
            #     PowerShellPath       = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            #     TaskDescription      = "User File Backup to OneDrive"
            #     AtLogOn              = $true
            #     # UseCurrentUser         = $true
            #     TaskPrincipalGroupId = "BUILTIN\Users"
            #     HideWithVBS          = $true
            #     # EnableRepetition       = $true
            #     VbsFileName          = "run-ps-hidden.vbs"  # Optional: Custom VBS file name
            # }
            
            # New-ScheduledTaskUtility @NewScheduledTaskUtilityTaskParams








            # $NewScheduledTaskUtilityTaskParams = @{
    
            #     ### General Task Settings ###
            #     TaskPath             = "AAD Migration"  # The path to the task in the Task Scheduler (like a folder name). 
            #     # Customize this to organize your tasks under a specific folder in Task Scheduler.
            
            #     TaskName             = "User File Backup to OneDrive"  # The name of the task. 
            #     # Customize it based on what the task does (e.g., "BackupUserFiles").
            
            #     TaskDescription      = "User File Backup to OneDrive"  # A short description of what the task does. 
            #     # Helpful for future reference when viewing tasks in Task Scheduler.
            
            #     ### Script Details (PowerShell or Other Script) ###
            #     ScriptDirectory      = "C:\ProgramData\AADMigration\Scripts"  # The directory where the PowerShell script is located. 
            #     # Customize this to point to where your script is stored.
                
            #     ScriptName           = "BackupUserFiles.Task.ps1"  # The name of the PowerShell script to run. 
            #     # This should match the file name of your PowerShell script.
            
            #     TaskArguments        = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""  
            #     # Arguments to pass when running the PowerShell script.
            #     # Typically, you want to leave this as-is for most use cases, but you can customize the arguments 
            #     # if you need to pass additional options to the script (e.g., different execution policies, paths, etc.).
            
            #     PowerShellPath       = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"  
            #     # Path to the PowerShell executable. 
            #     # Leave this as the default PowerShell path unless you want to use a custom PowerShell version or path.
            
            #     ### Task Trigger (When to Run the Task) ###
            #     AtLogOn              = $true  # Triggers the task to run when the user logs on. 
            #     # Set this to `$true` if you want the task to run at user logon. 
            #     # If you want to schedule it for another trigger (like daily or weekly), you can change this.
            
            #     ### Task Principal (Who the Task Runs As) ###
            #     # UseCurrentUser         = $true  # Uncomment this if you want the task to run as the current logged-in user. 
            #     # This is useful if the task needs user-level permissions. 
            #     # Leave this commented out if you're specifying a group or user in TaskPrincipalGroupId.
                
            #     TaskPrincipalGroupId = "BUILTIN\Users"  # Specify the user group under which the task will run.
            #     # Use this if you want the task to run under a specific group (e.g., "Administrators" or "Users").
            #     # Leave this as is if you don’t need to specify a custom group and are using UseCurrentUser.
            
            #     ### VBS Hidden Execution (Optional) ###
            #     HideWithVBS          = $true  # Set to `$true` if you want the task to run using a hidden VBScript (prevents a visible PowerShell window).
            #     # Leave this as `$false` if you don't need the task to run invisibly or hidden.
            
            #     VbsFileName          = "run-ps-hidden.vbs"  # The name of the VBScript file that will be created if `HideWithVBS` is enabled. 
            #     # You can customize this name if needed, but the default should work for most cases.
                
            #     ### Task Repetition (Optional) ###
            #     # EnableRepetition       = $true  # Uncomment this if you want the task to repeat at regular intervals (e.g., every 30 minutes).
            #     # Leave it commented out if you don't need the task to repeat.
            
            #     # TaskRepetitionDuration = "P1D"  # The total duration for which the task should repeat (e.g., "P1D" for 1 day).
            #     # Only relevant if `EnableRepetition` is set to `$true`. You can customize this based on your needs.
            
            #     # TaskRepetitionInterval = "PT30M"  # The interval between repetitions (e.g., "PT30M" for 30 minutes).
            #     # Only relevant if `EnableRepetition` is set to `$true`. Customize it for different intervals (e.g., "PT1H" for hourly).
            
            # }
            
            # # Execute the utility function to create the scheduled task using the parameters defined above
            # New-ScheduledTaskUtility @NewScheduledTaskUtilityTaskParams



            $NewScheduledTaskUtilityTaskParams = @{
                ### General Task Settings ###
                TaskPath             = "AAD Migration"
                TaskName             = "User File Backup to OneDrive"
                TaskDescription      = "Backup user files User to their own OneDrive"
            
                ### Script Details ###
                ScriptDirectory      = "C:\ProgramData\AADMigration\Scripts"
                ScriptName           = "BackupUserFiles.Task.ps1"
            
                ### Task Trigger ###
                AtLogOn              = $true
            
                ### Task Principal ###
                TaskPrincipalGroupId = "BUILTIN\Users"
            
                ### VBS Hidden Execution ###
                HideWithVBS          = $true
                VbsFileName          = "run-ps-hidden.vbs"
            }
            
            # Execute the utility function to create the scheduled task using the parameters defined above
            New-ScheduledTaskUtility @NewScheduledTaskUtilityTaskParams


         


            $RemoveExistingStatusFilesParams = @{
                LogFolder      = "logs"
                StatusFileName = "UserFilesBackupStatus.json"
            }
            # Remove existing status files
            Remove-ExistingStatusFiles @RemoveExistingStatusFilesParams


            $TriggerScheduledTaskParams = @{
                TaskPath = "AAD Migration"
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