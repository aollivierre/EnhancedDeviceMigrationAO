function Show-DeviceToastNotification {
    param (
        [string]$Title,
        [string]$Message,
        $AppLogo
    )
    # Show toast notification
    New-BurntToastNotification -Text $Title, $Message -AppLogo $AppLogo
}