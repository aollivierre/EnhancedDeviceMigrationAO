function Start-FileDownloadWithRetry {

    <#
    .SYNOPSIS
        Downloads a file from a specified URL with retry logic. Falls back to using WebClient if BITS transfer fails.

    .DESCRIPTION
        This function attempts to download a file from a specified source URL to a destination path using BITS (Background Intelligent Transfer Service). 
        If BITS fails after a specified number of retries, the function falls back to using the .NET WebClient class for the download.

    .PARAMETER Source
        The URL of the file to download.

    .PARAMETER Destination
        The file path where the downloaded file will be saved.

    .PARAMETER MaxRetries
        The maximum number of retry attempts if the download fails. Default is 3.

    .EXAMPLE
        Start-FileDownloadWithRetry -Source "https://example.com/file.zip" -Destination "C:\Temp\file.zip"

    .NOTES
        Author: Abdullah Ollivierre
        Date: 2024-08-15
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3
    )

    Begin {
        Write-EnhancedLog -Message "Starting Start-FileDownloadWithRetry function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Ensure the destination folder exists, create it if necessary
        $destinationFolder = Split-Path -Path $Destination -Parent
        if (-not (Test-Path -Path $destinationFolder)) {
            Write-EnhancedLog -Message "Destination folder does not exist. Creating folder: $destinationFolder" -Level "INFO"
            New-Item -Path $destinationFolder -ItemType Directory | Out-Null
        }
    }

    Process {
        $attempt = 0
        $success = $false

        while ($attempt -lt $MaxRetries -and -not $success) {
            try {
                $attempt++
                Write-EnhancedLog -Message "Attempt $attempt to download from $Source to $Destination" -Level "INFO"

                if (-not (Test-Path -Path $destinationFolder)) {
                    throw "Destination folder does not exist: $destinationFolder"
                }

                # Attempt download using BITS
                $bitsTransferParams = @{
                    Source      = $Source
                    Destination = $Destination
                    ErrorAction = "Stop"
                }
                Start-BitsTransfer @bitsTransferParams

                # Validate file existence and size after download
                if (Test-Path $Destination) {
                    $fileInfo = Get-Item $Destination
                    if ($fileInfo.Length -gt 0) {
                        Write-EnhancedLog -Message "Download successful using BITS on attempt $attempt. File size: $($fileInfo.Length) bytes" -Level "INFO"
                        $success = $true
                    }
                    else {
                        Write-EnhancedLog -Message "Download failed: File is empty after BITS transfer." -Level "ERROR"
                        throw "Download failed due to empty file after BITS transfer."
                    }
                }
                else {
                    Write-EnhancedLog -Message "Download failed: File not found after BITS transfer." -Level "ERROR"
                    throw "Download failed due to missing file after BITS transfer."
                }

            }
            catch {
                Write-EnhancedLog -Message "BITS transfer failed on attempt $attempt $($_.Exception.Message)" -Level "ERROR"
                if ($attempt -eq $MaxRetries) {
                    Write-EnhancedLog -Message "Maximum retry attempts reached. Falling back to WebClient for download." -Level "WARNING"
                    try {
                        $webClient = [System.Net.WebClient]::new()
                        $webClient.DownloadFile($Source, $Destination)
                    
                        # Validate file existence and size after download
                        if (Test-Path $Destination) {
                            $fileInfo = Get-Item $Destination
                            if ($fileInfo.Length -gt 0) {
                                Write-EnhancedLog -Message "Download successful using WebClient. File size: $($fileInfo.Length) bytes" -Level "INFO"
                                $success = $true
                            }
                            else {
                                Write-EnhancedLog -Message "Download failed: File is empty after WebClient download." -Level "ERROR"
                                throw "Download failed due to empty file after WebClient download."
                            }
                        }
                        else {
                            Write-EnhancedLog -Message "Download failed: File not found after WebClient download." -Level "ERROR"
                            throw "Download failed due to missing file after WebClient download."
                        }
                    }
                    catch {
                        Write-EnhancedLog -Message "WebClient download failed: $($_.Exception.Message)" -Level "ERROR"
                        throw "Download failed after multiple attempts using both BITS and WebClient."
                    }
                    
                }
                else {
                    Start-Sleep -Seconds 5
                }
            }
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Start-FileDownloadWithRetry function" -Level "NOTICE"
    }
}

# # Generate a timestamped folder within the TEMP directory
# $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
# $destinationFolder = [System.IO.Path]::Combine($env:TEMP, "OneDriveSetup_$timestamp")

# # Set up the parameters for downloading OneDrive Setup
# $downloadParams = @{
#     Source      = "https://go.microsoft.com/fwlink/?linkid=844652"  # OneDrive Setup URL
#     Destination = [System.IO.Path]::Combine($destinationFolder, "OneDriveSetup.exe")  # Local destination path in the timestamped folder
#     MaxRetries  = 3  # Number of retry attempts
# }

# # Call the Start-FileDownloadWithRetry function with splatted parameters
# Start-FileDownloadWithRetry @downloadParams