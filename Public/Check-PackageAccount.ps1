function Check-PackageAccount {
    <#
    .SYNOPSIS
        Prompts the user to check if the PPKG GUID account created by Windows Configuration Designer (WCD) is created in Entra ID and if it's excluded from all Conditional Access policies.

    .DESCRIPTION
        This function is designed to support administrators managing Provisioning Packages (PPKGs) created using Windows Configuration Designer (WCD), as detailed in the official Microsoft documentation: https://learn.microsoft.com/en-us/windows/configuration/provisioning-packages/provisioning-create-package.
        The function checks if a package account, generated during PPKG creation with an enrollment token for Entra ID, exists in Entra ID and verifies if it's excluded from all Conditional Access policies (CAPs).
        If the package_GUID account is not excluded from all CAPs, the `install-ppkg.ps1` function will encounter issues during the installation process.

    .PARAMETER PackageGuid
        The GUID of the package, used to construct the account email.

    .PARAMETER Domain
        The domain associated with the account in Entra ID.

    .OUTPUTS
        System.String
        A message indicating whether the account was found and if it's excluded from Conditional Access policies.

    .EXAMPLE
        Check-PackageAccount -PackageGuid "75cc34e6-141c-4577-8792-c238a4293408" -Domain "ictc-ctic.ca"
        This will check if the account "package_75cc34e6-141c-4577-8792-c238a4293408@ictc-ctic.ca" exists in Entra ID and is excluded from all Conditional Access policies.

    .NOTES
        Version: 1.2
        Author: Abdullah Ollivierre
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the package.")]
        [string]$PackageGuid,

        [Parameter(Mandatory = $true, HelpMessage = "The domain associated with the account in Entra ID.")]
        [string]$Domain
    )

    Begin {
        Write-EnhancedLog -Message "Initializing Check-PackageAccount function." -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Construct the package account email
            $packageAccount = "package_$PackageGuid@$Domain"
            Write-EnhancedLog -Message "Checking account: $packageAccount" -Level "INFO"

            # Prompt the user to proceed with the check
            $userResponse = Read-Host "Would you like to check if the account $packageAccount is created in Entra ID and is excluded from all Conditional Access policies? (Y/N)"
            if ($userResponse -ne 'Y') {
                Write-Host "Operation canceled by the user." -ForegroundColor Yellow
                return
            }


            # Prompt user for next steps
            $scriptOption = Read-Host "Would you like to run your own logic (type '1') or run the web script (type '2')?"
            if ($scriptOption -eq '1') {
                Write-Host "Running your own logic..." -ForegroundColor Cyan
                # User's logic here

                
                # Check if the account exists in Entra ID (simulated with a placeholder command)
                $accountExists = Get-MgUser -UserId $packageAccount -ErrorAction SilentlyContinue
                if ($null -eq $accountExists) {
                    Write-EnhancedLog -Message "Account $packageAccount does not exist in Entra ID." -Level "ERROR"
                    throw "Account not found."
                }

                Write-EnhancedLog -Message "Account $packageAccount exists in Entra ID." -Level "INFO"

                # Check if the account is excluded from all Conditional Access policies
                $excludedPolicies = Get-MgConditionalAccessPolicy | Where-Object {
                    $_.Conditions.Users.Exclude.Contains($packageAccount)
                }

                if ($excludedPolicies.Count -eq 0) {
                    Write-EnhancedLog -Message "Account $packageAccount is NOT excluded from any Conditional Access policies." -Level "WARNING"
                    Write-Host "Warning: The account is not excluded from any Conditional Access policies. The install-ppkg account will encounter issues during installation." -ForegroundColor Red
                }
                else {
                    Write-EnhancedLog -Message "Account $packageAccount is excluded from the following Conditional Access policies: $($excludedPolicies.DisplayName -join ', ')" -Level "INFO"
                    Write-Host "The account is excluded from the following Conditional Access policies: $($excludedPolicies.DisplayName -join ', ')" -ForegroundColor Green
                }

            }
            elseif ($scriptOption -eq '2') {
                Write-Host "Warning: The web script is not tested and relies on external dependencies. Please review the notes in C:\code\IntuneDeviceMigration\DeviceMigration\Scripts\Beta\Confirm-BreakGlassConditionalAccessExclusions.ps1 before proceeding." -ForegroundColor Yellow
                $confirmRun = Read-Host "Do you want to proceed with running the web script? (Y/N)"
                if ($confirmRun -eq 'Y') {
                    Write-Host "Downloading and running the web script..." -ForegroundColor Cyan
                    $scriptUrl = "https://raw.githubusercontent.com/thetolkienblackguy/EntraIdManagement/main/Confirm-BreakGlassConditionalAccessExclusions/Confirm-BreakGlassConditionalAccessExclusions.ps1"
                    $scriptContent = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing | Select-Object -ExpandProperty Content
                    Invoke-Expression $scriptContent
                }
                else {
                    Write-Host "Operation canceled by the user." -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "Invalid option selected. Operation canceled." -ForegroundColor Yellow
            }

            Write-EnhancedLog -Message "Check-PackageAccount function completed successfully." -Level "NOTICE"
        }
        catch {
            Write-EnhancedLog -Message "Error occurred in Check-PackageAccount function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Check-PackageAccount function." -Level "NOTICE"
        }
    }

    End {
        Write-EnhancedLog -Message "Check-PackageAccount function has fully completed." -Level "NOTICE"
    }
}

# # Example usage of the Check-PackageAccount function
# try {
#     # Define the package GUID and domain
#     $packageGuid = "75cc34e6-141c-4577-8792-c238a4293408"
#     $domain = "ictc-ctic.ca"

#     # Invoke the Check-PackageAccount function
#     Check-PackageAccount -PackageGuid $packageGuid -Domain $domain
# }
# catch {
#     Write-Host "An error occurred during the account check: $($_.Exception.Message)" -ForegroundColor Red
# }
