# function Test-ProvisioningPack {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$PPKGName
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Test-ProvisioningPack function" -Level "INFO"
#         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
#     }

#     Process {
#         try {
#             Write-EnhancedLog -Message "Checking if the provisioning package '$PPKGName' has been previously installed." -Level "INFO"

#             # Retrieve the status of the provisioning package
#             $PPKGStatus = Get-ProvisioningPackage -AllInstalledPackages | Where-Object { $_.PackagePath -like "*$PPKGName*" }

#             if ($PPKGStatus) {
#                 Write-EnhancedLog -Message "Provisioning package '$PPKGName' found to be previously installed." -Level "INFO"
#                 Write-EnhancedLog -Message "Removing previously installed provisioning package '$PPKGName'." -Level "INFO"
                
#                 # Extract the Package ID
#                 $PPKGID = $PPKGStatus.PackageID
#                 Remove-ProvisioningPackage -PackageId $PPKGID

#                 Write-EnhancedLog -Message "Successfully removed provisioning package with ID '$PPKGID'." -Level "INFO"
#             }
#             else {
#                 Write-EnhancedLog -Message "No previous installation found for provisioning package '$PPKGName'." -Level "INFO"
#             }
#         }
#         catch {
#             Write-EnhancedLog -Message "An error occurred while testing provisioning package '$PPKGName': $($_.Exception.Message)" -Level "ERROR"
#             Handle-Error -ErrorRecord $_
#         }
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Test-ProvisioningPack function" -Level "INFO"
#     }
# }
