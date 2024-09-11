# function Resolve-SID {
#     param (
#         [string]$AccountName
#     )

#     try {
#         $account = Get-WmiObject -Class Win32_UserAccount -Filter "Name='$AccountName'"
#         if ($account) {
#             # Use the SID directly
#             $sid = New-Object System.Security.Principal.SecurityIdentifier($account.SID)
#             return $sid
#         } else {
#             Write-EnhancedLog -Message "Unable to resolve SID for $AccountName." -Level "WARNING"
#             return $null
#         }
#     }
#     catch {
#         Write-EnhancedLog -Message "Error resolving SID for $AccountName $_" -Level "ERROR"
#         return $null
#     }
# }