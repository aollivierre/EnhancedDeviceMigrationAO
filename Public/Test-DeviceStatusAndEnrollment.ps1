function Test-DeviceStatusAndEnrollment {

    <#
.SYNOPSIS
    Evaluates the device's join status (Workgroup, Azure AD, Hybrid, or On-prem) and its Microsoft Intune enrollment status.

.DESCRIPTION
    This function retrieves the device's join status using `Get-DSRegStatus` and determines whether the device is joined to Workgroup, Azure AD, Hybrid, or On-prem environments. It also checks if the device is enrolled in Microsoft Intune (MDM). 
    Based on the evaluation, the function logs relevant details, displays the status in a form, and uses color-coded console outputs to reflect the device status. The function can also set appropriate exit codes based on the status to indicate whether a device migration is necessary.

.PARAMETER None
    This function takes no parameters.

.OUTPUTS
    Logs the device join and MDM enrollment status to enhanced logs and displays the status in both the console (color-coded) and a form window for the user.

.EXAMPLES
    Example 1:
    Test-DeviceStatusAndEnrollment

    This example checks the current device’s join status and Intune (MDM) enrollment status, logs the results, and displays them in a form and the console.

.NOTES
    - This function relies on the `Get-DSRegStatus` function to retrieve the device's registration and join status.
    - Color-coding is used in the console output to easily distinguish between different statuses.
    - The exit code 0 indicates the device is Azure AD joined and Intune enrolled, requiring no migration.
    - Other statuses may require further action, and the exit code is set accordingly.
    
#>

    [CmdletBinding()]
    param (


        [string]$Title,
        [string]$Message,
        [string]$ScriptPath,
        [Switch]$ExitOnCondition
        
    )
    
    begin {

        # Main script execution block
        $dsregStatus = Get-DSRegStatus

        Write-EnhancedLog -Message "Starting Test-DeviceStatusAndEnrollment" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters


        # Define the custom image path (ensure the path is correct)
        $iconPath = "$ScriptPath\Icon.png"  # Replace with the correct path to your custom icon
        
    }
    
    process {

        # Determine device join status and send notifications
        if ($dsregStatus.IsWorkgroup) {
            Write-EnhancedLog -Message "Device is Workgroup joined (not Azure AD, Hybrid, or On-prem Joined)."
            Show-DeviceToastNotification -Title "Device Status" -Message "Device is Workgroup joined" -AppLogo $iconPath
        }
        elseif ($dsregStatus.IsAzureADJoined -and -not $dsregStatus.IsHybridJoined) {
            Write-EnhancedLog -Message "Device is Azure AD Joined."
            Show-DeviceToastNotification -Title "Device Status" -Message "Device is Azure AD Joined" -AppLogo $iconPath
        }
        elseif ($dsregStatus.IsHybridJoined) {
            Write-EnhancedLog -Message "Device is Hybrid Joined (both On-prem and Azure AD Joined)."
            Show-DeviceToastNotification -Title "Device Status" -Message "Device is Hybrid Joined" -AppLogo $iconPath
        }
        elseif ($dsregStatus.IsOnPremJoined) {
            Write-EnhancedLog -Message "Device is On-prem Joined only."
            Show-DeviceToastNotification -Title "Device Status" -Message "Device is On-prem Joined" -AppLogo $iconPath
        }

        # Determine MDM enrollment status and send notification
        if ($dsregStatus.IsMDMEnrolled) {
            Write-EnhancedLog -Message "Device is Intune Enrolled."
            Show-DeviceToastNotification -Title "MDM Status" -Message "Device is Intune Enrolled" -AppLogo $iconPath
        }
        else {
            Write-EnhancedLog -Message "Device is NOT Intune Enrolled."
            Show-DeviceToastNotification -Title "MDM Status" -Message "Device is NOT Intune Enrolled" -AppLogo $iconPath
        }

        # Exit code based on Azure AD and MDM status
        if ($dsregStatus.IsAzureADJoined -and -not $dsregStatus.IsHybridJoined -and $dsregStatus.IsMDMEnrolled) {
            Write-EnhancedLog -Message "Device is Azure AD Joined and Intune Enrolled. No migration needed. Here is the output from: dsregcmd /status" -Level 'WARNING'



            # Output device join status using Write-EnhancedLog with levels
            Write-EnhancedLog -Message "Device Join Status:" -Level "INFO"
            Write-EnhancedLog -Message "-------------------" -Level "INFO"
            Write-EnhancedLog -Message "Is Workgroup: $($dsregStatus.IsWorkgroup)" -Level "INFO"
            Write-EnhancedLog -Message "Is Azure AD Joined: $($dsregStatus.IsAzureADJoined)" -Level "INFO"
            Write-EnhancedLog -Message "Is Hybrid Joined: $($dsregStatus.IsHybridJoined)" -Level "INFO"
            Write-EnhancedLog -Message "Is On-prem Joined: $($dsregStatus.IsOnPremJoined)" -Level "INFO"

            # Output MDM Enrollment Status using Write-EnhancedLog
            if ($dsregStatus.IsMDMEnrolled) {
                Write-EnhancedLog -Message "MDM Enrollment: Yes" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "MDM Enrollment: No" -Level "WARNING"
            }

            # If the MDM URL exists, display it using Write-EnhancedLog
            if ($dsregStatus.MDMUrl) {
                Write-EnhancedLog -Message "MDM URL: $($dsregStatus.MDMUrl)" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "MDM URL not available" -Level "WARNING"
            }




            # Output to the console with color coding
            Write-Host "Device Join Status:" -ForegroundColor White
            Write-Host "-------------------" -ForegroundColor White

            # Workgroup status
            if ($dsregStatus.IsWorkgroup) {
                Write-Host "Is Workgroup: Yes" -ForegroundColor Red
            }
            else {
                Write-Host "Is Workgroup: No" -ForegroundColor Green
            }

            # Azure AD Joined status
            if ($dsregStatus.IsAzureADJoined) {
                Write-Host "Is Azure AD Joined: Yes" -ForegroundColor Green
            }
            else {
                Write-Host "Is Azure AD Joined: No" -ForegroundColor Red
            }

            # Hybrid Joined status
            if ($dsregStatus.IsHybridJoined) {
                Write-Host "Is Hybrid Joined: Yes" -ForegroundColor Yellow
            }
            else {
                Write-Host "Is Hybrid Joined: No" -ForegroundColor Green
            }

            # On-prem Joined status
            if ($dsregStatus.IsOnPremJoined) {
                Write-Host "Is On-prem Joined: Yes" -ForegroundColor Yellow
            }
            else {
                Write-Host "Is On-prem Joined: No" -ForegroundColor Green
            }

            # Output MDM Enrollment Status using color coding
            if ($dsregStatus.IsMDMEnrolled) {
                Write-Host "MDM Enrollment: Yes" -ForegroundColor Green
            }
            else {
                Write-Host "MDM Enrollment: No" -ForegroundColor Red
            }

            # If the MDM URL exists, display it in Green, otherwise show a warning
            if ($dsregStatus.MDMUrl) {
                Write-Host "MDM URL: $($dsregStatus.MDMUrl)" -ForegroundColor Green
            }
            else {
                Write-Host "MDM URL: Not Available" -ForegroundColor Red
            }





            # Wait-Debugger

            Show-DeviceStatusForm
            # exit 0 # Do not migrate: Device is Azure AD Joined and Intune Enrolled



            if ($ExitOnCondition) {
                Write-Host "Exiting script with code 0 as per user option."
                exit 0 # Do not migrate: Device is Azure AD Joined and Intune Enrolled
            }
            else {
                Write-Host "ExitOnCondition switch is not set. Continuing execution."
            }



        }
        else {

            Write-EnhancedLog -Message "Device is not 100% Azure AD joined or is hybrid/on-prem joined. Here is the output from: dsregcmd /status"



        
            # Output device join status using Write-EnhancedLog with levels
            Write-EnhancedLog -Message "Device Join Status:" -Level "INFO"
            Write-EnhancedLog -Message "-------------------" -Level "INFO"
            Write-EnhancedLog -Message "Is Workgroup: $($dsregStatus.IsWorkgroup)" -Level "INFO"
            Write-EnhancedLog -Message "Is Azure AD Joined: $($dsregStatus.IsAzureADJoined)" -Level "INFO"
            Write-EnhancedLog -Message "Is Hybrid Joined: $($dsregStatus.IsHybridJoined)" -Level "INFO"
            Write-EnhancedLog -Message "Is On-prem Joined: $($dsregStatus.IsOnPremJoined)" -Level "INFO"

            # Output MDM Enrollment Status using Write-EnhancedLog
            if ($dsregStatus.IsMDMEnrolled) {
                Write-EnhancedLog -Message "MDM Enrollment: Yes" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "MDM Enrollment: No" -Level "WARNING"
            }

            # If the MDM URL exists, display it using Write-EnhancedLog
            if ($dsregStatus.MDMUrl) {
                Write-EnhancedLog -Message "MDM URL: $($dsregStatus.MDMUrl)" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "MDM URL not available" -Level "WARNING"
            }


            # Output to the console with color coding
            Write-Host "Device Join Status:" -ForegroundColor White
            Write-Host "-------------------" -ForegroundColor White

            # Workgroup status
            if ($dsregStatus.IsWorkgroup) {
                Write-Host "Is Workgroup: Yes" -ForegroundColor Red
            }
            else {
                Write-Host "Is Workgroup: No" -ForegroundColor Green
            }

            # Azure AD Joined status
            if ($dsregStatus.IsAzureADJoined) {
                Write-Host "Is Azure AD Joined: Yes" -ForegroundColor Green
            }
            else {
                Write-Host "Is Azure AD Joined: No" -ForegroundColor Red
            }

            # Hybrid Joined status
            if ($dsregStatus.IsHybridJoined) {
                Write-Host "Is Hybrid Joined: Yes" -ForegroundColor Yellow
            }
            else {
                Write-Host "Is Hybrid Joined: No" -ForegroundColor Green
            }

            # On-prem Joined status
            if ($dsregStatus.IsOnPremJoined) {
                Write-Host "Is On-prem Joined: Yes" -ForegroundColor Yellow
            }
            else {
                Write-Host "Is On-prem Joined: No" -ForegroundColor Green
            }

            # Output MDM Enrollment Status using color coding
            if ($dsregStatus.IsMDMEnrolled) {
                Write-Host "MDM Enrollment: Yes" -ForegroundColor Green
            }
            else {
                Write-Host "MDM Enrollment: No" -ForegroundColor Red
            }

            # If the MDM URL exists, display it in Green, otherwise show a warning
            if ($dsregStatus.MDMUrl) {
                Write-Host "MDM URL: $($dsregStatus.MDMUrl)" -ForegroundColor Green
            }
            else {
                Write-Host "MDM URL: Not Available" -ForegroundColor Red
            }

            Show-DeviceStatusForm
            # Migrate: All other cases where the device is not 100% Azure AD joined or is hybrid/on-prem joined
            # exit 1
        }

        
    }
    
    end {

        Write-EnhancedLog -Message "Exiting Test-DeviceStatusAndEnrollment" -Level "Notice"
        
    }
}