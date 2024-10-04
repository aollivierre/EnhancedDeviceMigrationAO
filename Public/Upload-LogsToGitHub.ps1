function Upload-LogsToGitHub {
    <#
    .SYNOPSIS
    Upload zipped log files to a GitHub repository.

    .DESCRIPTION
    This function compresses log files from a specified directory, clones a GitHub repository, 
    and uploads the zipped logs to the repository using Git. It handles Git user configuration 
    based on whether the script is running as SYSTEM or a regular user.

    .PARAMETER SecurePAT
    A secure string containing the GitHub Personal Access Token (PAT) for authentication.

    .PARAMETER GitExePath
    The path to the Git executable. Defaults to "C:\Program Files\Git\bin\git.exe".

    .PARAMETER LogsFolderPath
    The path to the folder containing logs to be uploaded.

    .PARAMETER TempCopyPath
    A temporary directory where the logs will be copied before zipping.

    .PARAMETER TempGitPath
    A temporary directory for Git operations.

    .PARAMETER GitUsername
    Your GitHub username.

    .PARAMETER BranchName
    The Git branch to push the commits to. Defaults to "main".

    .PARAMETER CommitMessage
    The message to be used for the Git commit.

    .PARAMETER RepoName
    The name of the GitHub repository to which the logs will be pushed.

    .PARAMETER JobName
    The name of the job, which will be used for folder organization inside the Git repository.

    .EXAMPLE
    $params = @{
        SecurePAT       = $securePat
        GitExePath      = "C:\Program Files\Git\bin\git.exe"
        LogsFolderPath  = "C:\logs"
        TempCopyPath    = "C:\temp-logs"
        TempGitPath     = "C:\temp-git"
        GitUsername     = "aollivierre"
        BranchName      = "main"
        CommitMessage   = "Add logs.zip"
        RepoName        = "syslog"
        JobName         = "AADMigration"
    }

    Upload-LogsToGitHub @params
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "GitHub Personal Access Token as a SecureString")]
        [SecureString]$SecurePAT,

        [Parameter(Mandatory = $false, HelpMessage = "Path to Git executable", Position = 1)]
        [string]$GitExePath = "C:\Program Files\Git\bin\git.exe",

        [Parameter(Mandatory = $false, HelpMessage = "Path to logs folder", Position = 2)]
        [string]$LogsFolderPath = "C:\logs",

        [Parameter(Mandatory = $false, HelpMessage = "Temporary directory for logs copy", Position = 3)]
        [string]$TempCopyPath = "C:\temp-logs",

        [Parameter(Mandatory = $false, HelpMessage = "Temporary directory for Git operations", Position = 4)]
        [string]$TempGitPath = "C:\temp-git",

        [Parameter(Mandatory = $true, HelpMessage = "GitHub username", Position = 5)]
        [string]$GitUsername,

        [Parameter(Mandatory = $false, HelpMessage = "Branch to push changes to", Position = 6)]
        [string]$BranchName = "main",

        [Parameter(Mandatory = $false, HelpMessage = "Git commit message", Position = 7)]
        [string]$CommitMessage = "Add logs.zip",

        [Parameter(Mandatory = $true, HelpMessage = "Name of the GitHub repository", Position = 8)]
        [string]$RepoName,

        [Parameter(Mandatory = $false, HelpMessage = "Job name for folder structure", Position = 9)]
        [string]$JobName = "AADMigration"
    )

    try {
        Write-EnhancedLog -Message "Starting Upload-LogsToGitHub function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Convert SecureString to plain text
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePAT)
        $PersonalAccessToken = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)

        # $PersonalAccessToken

        # Wait-Debugger

        # Build Git repo URL
        $RepoUrlSanitized = "https://github.com/$GitUsername/$RepoName.git"
        $RepoUrl = "https://{0}:{1}@github.com/{2}/$RepoName.git" -f $GitUsername, $PersonalAccessToken, $GitUsername

        # Clean up temp Git path if it exists
        if (Test-Path -Path $TempGitPath) {
            Write-EnhancedLog -Message "Removing $TempGitPath..."
            Remove-Item -Path $TempGitPath -Recurse -Force
        }

        # Ensure temp directories exist
        if (-not (Test-Path -Path $TempGitPath)) {
            New-Item -Path $TempGitPath -ItemType Directory | Out-Null
        }

        if (Test-Path -Path $TempCopyPath) {
            Write-EnhancedLog -Message "Removing $TempCopyPath..."
            Remove-Item -Path $TempCopyPath -Recurse -Force
        }

        if (-not (Test-Path -Path $TempCopyPath)) {
            New-Item -Path $TempCopyPath -ItemType Directory | Out-Null
        }

        # Copy logs to temp path
        Copy-FilesWithRobocopy -Source $LogsFolderPath -Destination $TempCopyPath -FilePattern '*' -Exclude ".git"

        # Zip the copied logs
        $TempZipFile = Join-Path -Path $TempGitPath -ChildPath "logs.zip"
        $params = @{
            SourceDirectory = $TempCopyPath
            ZipFilePath     = $TempZipFile
        }
        Zip-Directory @params

        # Ensure zip file was created
        if (-Not (Test-Path -Path $TempZipFile)) {
            Write-EnhancedLog -Message "Failed to zip the logs folder." -ForegroundColor Red
            exit 1
        }

        # Clone the repository
        Set-Location -Path $TempGitPath
        $RepoPath = Join-Path -Path $TempGitPath -ChildPath $RepoName
        if (-Not (Test-Path -Path $RepoPath)) {
            Write-EnhancedLog -Message "Cloning repository from $RepoUrlSanitized..."
            & "$GitExePath" clone $RepoUrl
        }

        # Set up folder structure for logs
        $ComputerName = $env:COMPUTERNAME
        $CurrentDate = Get-Date -Format "yyyy-MM-dd"
        $CurrentTime = Get-Date -Format "h-mm-tt"  # Example: 7-08-AM
        $JobFolder = Join-Path -Path $RepoPath -ChildPath "$ComputerName\$CurrentDate\$CurrentTime\$JobName"

        # Ensure the directory structure exists
        if (-Not (Test-Path -Path $JobFolder)) {
            New-Item -Path $JobFolder -ItemType Directory -Force | Out-Null
        }

        # Copy the zip file to the repository folder
        Copy-Item -Path $TempZipFile -Destination $JobFolder -Force

        # Configure Git user identity based on account type
        Set-Location -Path $RepoPath
        $IsSystem = Test-RunningAsSystem
        if ($IsSystem) {
            & "$GitExePath" config user.email "system@example.com"
            & "$GitExePath" config user.name "System User"
            Write-EnhancedLog -Message "Configured Git identity for SYSTEM account." -Level "INFO"
        }
        else {
            $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $CurrentUserEmail = "$($CurrentUser.Replace('\', '_'))@example.com"
            & "$GitExePath" config user.email $CurrentUserEmail
            & "$GitExePath" config user.name $CurrentUser
            Write-EnhancedLog -Message "Configured Git identity for user: $CurrentUser." -Level "INFO"
        }

        # Add, commit, and push changes to the repository
        & "$GitExePath" add *
        & "$GitExePath" commit -m "$CommitMessage from $ComputerName on $CurrentDate"
        & "$GitExePath" push origin $BranchName

        Write-EnhancedLog -Message "Zipped log file copied to $JobFolder and pushed to the repository." -ForegroundColor Green

        # Clean up temporary directories
        Set-Location -Path "C:\" # Ensure we're not inside the Git directory
        Remove-Item -Path $TempGitPath -Recurse -Force
        Write-EnhancedLog -Message "Process completed and temp $TempGitPath directory cleaned up." -ForegroundColor Green

    }
    catch {
        Handle-Error -ErrorRecord $_
    }
    finally {
        Write-EnhancedLog -Message "Exiting Upload-LogsToGitHub function" -Level "NOTICE"
    }
}
