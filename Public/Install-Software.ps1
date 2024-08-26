# Main function to manage the entire OneDrive installation and configuration
function Install-Software {
    <#
    .SYNOPSIS
        Installs a specified software and performs pre- and post-installation validation.

    .DESCRIPTION
        This function handles the installation of software by downloading the installer, validating the software before and after installation, 
        and performing any necessary post-installation tasks such as syncing or configuring the software.

    .PARAMETER MigrationPath
        The base directory path where the setup file will be stored.

    .PARAMETER SoftwareName
        The name of the software to be installed, used for validation.

    .PARAMETER SetupUri
        The URL from which the setup executable will be downloaded.

    .PARAMETER SetupFile
        The name of the setup executable file.

    .PARAMETER RegKey
        The registry key path used for validating the installed version.

    .PARAMETER MinVersion
        The minimum required version of the software to validate the installation.

    .PARAMETER ExePath
        The path to the executable file used for file-based validation.

    .PARAMETER ScheduledTaskName
        The name of the scheduled task used for any post-installation tasks.

    .PARAMETER ScheduledTaskDescription
        A description for the scheduled task.

    .PARAMETER SetupArgumentList
        The arguments passed to the installer executable during installation.

    .PARAMETER KFM
        Specifies whether to perform a Known Folder Move (KFM) sync after installation. Default is $false.

    .PARAMETER TimestampPrefix
        A prefix used for naming the timestamped folder in the TEMP directory. Default is 'Setup_'.

    .EXAMPLE
        $installParams = @{
            MigrationPath           = "C:\Migration"
            SoftwareName            = "OneDrive"
            SetupUri                = "https://go.microsoft.com/fwlink/?linkid=844652"
            SetupFile               = "OneDriveSetup.exe"
            RegKey                  = "HKLM:\SOFTWARE\Microsoft\OneDrive"
            MinVersion              = [version]"23.143.0712.0001"
            ExePath                 = "C:\Program Files\Microsoft OneDrive\OneDrive.exe"
            ScheduledTaskName       = "OneDriveRemediation"
            ScheduledTaskDescription= "Restart OneDrive to kick off KFM sync"
            SetupArgumentList       = "/allusers"
            KFM                     = $true
            TimestampPrefix         = "OneDriveSetup_"
        }
        Install-Software @installParams

    .NOTES
        Author: Abdullah Ollivierre
        Date: 2024-08-15
    #>

    [CmdletBinding()]
    param (
        [string]$MigrationPath,
        [string]$SoftwareName,
        [string]$SetupUri,
        [string]$SetupFile,
        [string]$RegKey,
        [version]$MinVersion,
        [string]$ExePath,
        [string]$ScheduledTaskName,
        [string]$ScheduledTaskDescription,
        [string]$SetupArgumentList,
        [bool]$KFM = $false,
        [string]$TimestampPrefix # Default prefix for the timestamped folder
    )

    Begin {
        Write-EnhancedLog -Message "Starting Install-Software function for $SoftwareName" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Ensure the script is running with elevated privileges
        CheckAndElevate

        # Generate a timestamped folder within the TEMP directory
        $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $destinationFolder = [System.IO.Path]::Combine($env:TEMP, "$TimestampPrefix$timestamp")
        $SetupPath = [System.IO.Path]::Combine($destinationFolder, $SetupFile)
    }

    Process {
        # Step 1: Pre-installation validation
        Write-EnhancedLog -Message "Step 1: Performing pre-installation validation for $SoftwareName..." -Level "INFO"
        $preInstallParams = @{
            SoftwareName        = $SoftwareName
            MinVersion          = $MinVersion
            RegistryPath        = $RegKey
            ExePath             = $ExePath
            MaxRetries          = 3
            DelayBetweenRetries = 5
        }
        $preInstallCheck = Validate-SoftwareInstallation @preInstallParams
        if ($preInstallCheck.IsInstalled) {
            Write-EnhancedLog -Message "$SoftwareName version $($preInstallCheck.Version) is already installed. Skipping installation." -Level "INFO"
            return
        }
        Write-EnhancedLog -Message "$SoftwareName is not currently installed or needs an update." -Level "INFO"

        # Step 2: Download the setup file if not already present
        Write-EnhancedLog -Message "Step 2: Downloading $SoftwareName setup..." -Level "INFO"
        if (-not (Test-Path -Path $SetupPath)) {
            Download-OneDriveSetup -ODSetupUri $SetupUri -ODSetupPath $SetupPath
        } else {
            Write-EnhancedLog -Message "$SoftwareName setup already downloaded at $SetupPath" -Level "INFO"
        }

        # Step 3: Install the software
        Write-EnhancedLog -Message "Step 3: Installing $SoftwareName..." -Level "INFO"
        Install-OneDriveSetup -ODSetupPath $SetupPath -SetupArgumentList $SetupArgumentList

        # Step 4: Post-installation validation
        Write-EnhancedLog -Message "Step 4: Performing post-installation validation for $SoftwareName..." -Level "INFO"
        $postInstallCheck = Validate-SoftwareInstallation @preInstallParams
        if ($postInstallCheck.IsInstalled) {
            Write-EnhancedLog -Message "$SoftwareName version $($postInstallCheck.Version) installed successfully." -Level "INFO"
        } else {
            Write-EnhancedLog -Message "$SoftwareName installation failed." -Level "ERROR"
            throw "$SoftwareName installation validation failed."
        }

        # Step 5: Perform KFM sync if enabled
        if ($KFM) {
            Write-EnhancedLog -Message "Step 5: Performing KFM sync for $SoftwareName..." -Level "INFO"
            Perform-KFMSync -OneDriveExePath $ExePath -ScheduledTaskName $ScheduledTaskName -ScheduledTaskDescription $ScheduledTaskDescription
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Install-Software function for $SoftwareName" -Level "NOTICE"
    }
}



# $installParams = @{
#     MigrationPath            = "C:\ProgramData\AADMigration"
#     SoftwareName             = "OneDrive"
#     SetupUri                 = "https://go.microsoft.com/fwlink/?linkid=844652"
#     SetupFile                = "OneDriveSetup.exe"
#     RegKey                   = "HKLM:\SOFTWARE\Microsoft\OneDrive"
#     MinVersion               = [version]"24.146.0721.0003"
#     ExePath                  = "C:\Program Files\Microsoft OneDrive\OneDrive.exe"
#     ScheduledTaskName        = "OneDriveRemediation"
#     ScheduledTaskDescription = "Restart OneDrive to kick off KFM sync"
#     SetupArgumentList        = "/allusers"
#     KFM                      = $true
#     TimestampPrefix          = "OneDriveSetup_"
# }

# Install-Software @installParams