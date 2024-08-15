# function Start-BitsTransferWithRetry {
#     param (
#         [string]$Source,
#         [string]$Destination,
#         [int]$MaxRetries = 3
#     )
#     $attempt = 0
#     $success = $false

#     while ($attempt -lt $MaxRetries -and -not $success) {
#         try {
#             $attempt++
#             if (-not (Test-Path -Path (Split-Path $Destination -Parent))) {
#                 throw "Destination path does not exist: $(Split-Path $Destination -Parent)"
#             }
#             $bitsTransferParams = @{
#                 Source      = $Source
#                 Destination = $Destination
#                 ErrorAction = "Stop"
#             }
#             Start-BitsTransfer @bitsTransferParams
#             $success = $true
#         }
#         catch {
#             Write-Log "Attempt $attempt failed: $_" -Level "ERROR"
#             if ($attempt -eq $MaxRetries) {
#                 throw "Maximum retry attempts reached. Download failed."
#             }
#             Start-Sleep -Seconds 5
#         }
#     }
# }