function Download-ODSyncUtil {
    <#
    .SYNOPSIS
    Downloads and extracts the latest ODSyncUtil from the OneDrive Sync Utility GitHub repository for Windows 11.

    .DESCRIPTION
    The Download-ODSyncUtil function retrieves the latest release of ODSyncUtil from the GitHub repository, downloads the ZIP file, extracts it, and places the executable in the specified destination folder.

    .PARAMETER Destination
    The destination folder where ODSyncUtil.exe will be stored.

    .PARAMETER ApiUrl
    The GitHub API URL to retrieve the latest release information.

    .PARAMETER ZipFileName
    The name of the ZIP file to be downloaded (e.g., "ODSyncUtil-64-bit.zip").

    .PARAMETER ExecutableName
    The name of the executable to be extracted from the ZIP file (e.g., "ODSyncUtil.exe").

    .PARAMETER MaxRetries
    The maximum number of retries for the download process.

    .EXAMPLE
    $params = @{
        Destination    = "C:\YourPath\Files\ODSyncUtil.exe"
        ApiUrl         = "https://api.github.com/repos/rodneyviana/ODSyncUtil/releases/latest"
        ZipFileName    = "ODSyncUtil-64-bit.zip"
        ExecutableName = "ODSyncUtil.exe"
        MaxRetries     = 3
    }
    Download-ODSyncUtil @params
    Downloads and extracts ODSyncUtil.exe to the specified destination folder.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [string]$ApiUrl,

        [Parameter(Mandatory = $true)]
        [string]$ZipFileName,

        [Parameter(Mandatory = $true)]
        [string]$ExecutableName,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3
    )

    Begin {
        Write-EnhancedLog -Message "Starting Download-ODSyncUtil function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

    }

    Process {
        try {
            # Get the latest release info from GitHub
            Write-EnhancedLog -Message "Retrieving latest release info from GitHub API: $ApiUrl" -Level "INFO"
            $releaseInfo = Invoke-RestMethod -Uri $ApiUrl

            # Find the download URL for the specified ZIP file
            $downloadUrl = $releaseInfo.assets | Where-Object { $_.name -eq $ZipFileName } | Select-Object -ExpandProperty browser_download_url

            if (-not $downloadUrl) {
                $errorMessage = "No matching file found for $ZipFileName"
                Write-EnhancedLog -Message $errorMessage -Level "Critical"
                throw $errorMessage
            }

            # Define the ZIP file path
            $zipFilefolder = Split-Path -Path $Destination -Parent
            $zipFilePath = Join-Path -Path (Split-Path -Path $Destination -Parent) -ChildPath $ZipFileName


            #Remove the Existing Zip Folder Folder if found
            if (Test-Path -Path $zipFilefolder) {
                Write-EnhancedLog -Message "Found $zipFilefolder. Removing it..." -Level "INFO"
                try {
                    Remove-Item -Path $zipFilefolder -Recurse -Force
                    Write-EnhancedLog -Message "Successfully removed $zipFilefolder." -Level "INFO"
                }
                catch {
                    Write-EnhancedLog -Message "Failed to remove $zipFilefolder $($_.Exception.Message)" -Level "ERROR"
                    Handle-Error -ErrorRecord $_
                    throw $_
                }
            }
            else {
                Write-EnhancedLog -Message "$zipFilefolder not found. No action required." -Level "INFO"
            }

            # $DBG


            # Define the splatting parameters for the download
            $downloadParams = @{
                Source      = $downloadUrl
                Destination = $zipFilePath
                MaxRetries  = $MaxRetries
            }

            Write-EnhancedLog -Message "Downloading $ZipFileName from: $downloadUrl to: $zipFilePath" -Level "INFO"
            Start-FileDownloadWithRetry @downloadParams

            # Extract the executable from the ZIP file
            Write-EnhancedLog -Message "Extracting $ZipFileName to: $(Split-Path -Path $Destination -Parent)" -Level "INFO"
            Expand-Archive -Path $zipFilePath -DestinationPath (Split-Path -Path $Destination -Parent) -Force

            # Move the extracted executable to the desired location
            $extractedExePath = Join-Path -Path (Split-Path -Path $Destination -Parent) -ChildPath $ExecutableName
            if (Test-Path -Path $extractedExePath) {
                Write-EnhancedLog -Message "Moving $ExecutableName to: $Destination" -Level "INFO"
                Move-Item -Path $extractedExePath -Destination $Destination -Force

                # Remove the downloaded ZIP file and the extracted folder
                # Write-EnhancedLog -Message "Cleaning up: Removing downloaded ZIP file from $zipFilePath and extracted files from $extractedExePath" -Level "INFO"
                # Remove-Item -Path $zipFilePath -Force
                # Remove-Item -Path (Split-Path -Path $extractedExePath -Parent) -Recurse -Force
            }
            else {
                $errorMessage = "$ExecutableName not found after extraction."
                Write-EnhancedLog -Message $errorMessage -Level "Critical"
                throw $errorMessage
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Download-ODSyncUtil function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Download-ODSyncUtil function" -Level "Notice"
    }
}

# # # # Example usage
# $params = @{
#     Destination    = "C:\code\IntuneDeviceMigration\DeviceMigration\Files\ODSyncUtil\ODSyncUtil.exe"
#     ApiUrl         = "https://api.github.com/repos/rodneyviana/ODSyncUtil/releases/latest"
#     ZipFileName    = "ODSyncUtil-64-bit.zip"
#     ExecutableName = "ODSyncUtil.exe"
#     MaxRetries     = 3
# }
# Download-ODSyncUtil @params
