function Get-PowerShellPath {
    <#
    .SYNOPSIS
        Retrieves the path to the installed PowerShell executable.

    .DESCRIPTION
        This function checks for the existence of PowerShell 7 and PowerShell 5 on the system.
        It returns the path to the first version found, prioritizing PowerShell 7. If neither
        is found, an error is thrown.

    .EXAMPLE
        $pwshPath = Get-PowerShellPath
        Write-Host "PowerShell found at: $pwshPath"

    .NOTES
        Author: Abdullah Ollivierre
        Date: 2024-08-15
    #>

    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting Get-PowerShellPath function" -Level "NOTICE"
    }

    Process {
        $pwsh7Path = "C:\Program Files\PowerShell\7\pwsh.exe"
        $pwsh5Path = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

        if (Test-Path $pwsh7Path) {
            Write-EnhancedLog -Message "PowerShell 7 found at $pwsh7Path" -Level "INFO"
            return $pwsh7Path
        }
        elseif (Test-Path $pwsh5Path) {
            Write-EnhancedLog -Message "PowerShell 5 found at $pwsh5Path" -Level "INFO"
            return $pwsh5Path
        }
        else {
            $errorMessage = "Neither PowerShell 7 nor PowerShell 5 was found on this system."
            Write-EnhancedLog -Message $errorMessage -Level "ERROR"
            throw $errorMessage
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-PowerShellPath function" -Level "NOTICE"
    }
}


# # Get the path to the installed PowerShell executable
# try {
#     $pwshPath = Get-PowerShellPath
#     Write-Host "PowerShell executable found at: $pwshPath"
    
#     # Example: Start a new PowerShell session using the found path
#     Start-Process -FilePath $pwshPath -ArgumentList "-NoProfile", "-Command", "Get-Process" -NoNewWindow -Wait
# }
# catch {
#     Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
# }