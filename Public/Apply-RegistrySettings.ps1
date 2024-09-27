# function Apply-RegistrySettings {
#     <#
#     .SYNOPSIS
#     Applies multiple registry settings and provides a summary of success, failures, and warnings.

#     .DESCRIPTION
#     This function applies registry settings from a provided hash table and logs the results, including a final summary of success, skipped, and failed settings.

#     .PARAMETER RegistrySettings
#     A hash table containing the registry settings to apply. The hash table keys should be registry paths, and the values should be another hash table with registry names, types, and data.

#     .EXAMPLE
#     Apply-RegistrySettings -RegistrySettings $RegistrySettings
#     #>

#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         $RegistrySettings
#     )

#     Begin {
#         # Initialize counters and summary table
#         $infoCount = 0
#         $warningCount = 0
#         $errorCount = 0
#         $summaryTable = [System.Collections.Generic.List[PSCustomObject]]::new()

#         Write-EnhancedLog -Message "Applying registry settings" -Level "INFO"
#     }

#     Process {
#         foreach ($regPath in $RegistrySettings.Keys) {
#             foreach ($regName in $RegistrySettings[$regPath].Keys) {
#                 $regSetting = $RegistrySettings[$regPath][$regName]

#                 $summaryRow = [PSCustomObject]@{
#                     RegistryPath  = $regPath
#                     RegistryName  = $regName
#                     RegistryValue = if ($null -ne $regSetting["Data"]) { $regSetting["Data"] } else { "null" }
#                     Status        = ""
#                 }

#                 if ($null -ne $regSetting["Data"]) {
#                     Write-EnhancedLog -Message "Setting registry value $regName at $regPath" -Level "INFO"
#                     $infoCount++

#                     $regParams = @{
#                         RegKeyPath = $regPath
#                         RegValName = $regName
#                         RegValType = $regSetting["Type"]
#                         RegValData = $regSetting["Data"]
#                     }

#                     # If the data is an empty string, explicitly set it as such
#                     if ($regSetting["Data"] -eq "") {
#                         $regParams.RegValData = ""
#                     }

#                     try {
#                         # Call the Set-RegistryValue function and capture the result
#                         $setRegistryResult = Set-RegistryValue @regParams

#                         # Build decision-making logic based on the result
#                         if ($setRegistryResult -eq $true) {
#                             Write-EnhancedLog -Message "Successfully set the registry value: $($regParams.RegValName) at $($regParams.RegKeyPath)" -Level "INFO"
#                             $summaryRow.Status = "Success"
#                         }
#                         else {
#                             Write-EnhancedLog -Message "Failed to set the registry value: $($regParams.RegValName) at $($regParams.RegKeyPath)" -Level "ERROR"
#                             $summaryRow.Status = "Failed"
#                             $errorCount++
#                         }

#                         Write-EnhancedLog -Message "Registry value $regName at $regPath set" -Level "INFO"
                        
#                     }
#                     catch {
#                         Write-EnhancedLog -Message "Error setting registry value $regName at $regPath $($_.Exception.Message)" -Level "ERROR"
#                         $errorCount++
#                         $summaryRow.Status = "Failed"
#                     }
#                 }
#                 else {
#                     Write-EnhancedLog -Message "Skipping registry value $regName at $regPath due to null data" -Level "WARNING"
#                     $warningCount++
#                     $summaryRow.Status = "Skipped"
#                 }

#                 $summaryTable.Add($summaryRow)
#             }
#         }
#     }

#     End {
#         # Final Summary Report
#         Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"
#         Write-EnhancedLog -Message "Final Summary Report" -Level "NOTICE"
#         Write-EnhancedLog -Message "Total registry settings processed: $($infoCount + $warningCount + $errorCount)" -Level "INFO"
#         Write-EnhancedLog -Message "Successfully applied registry settings: $infoCount" -Level "INFO"
#         Write-EnhancedLog -Message "Skipped registry settings (due to null data): $warningCount" -Level "WARNING"
#         Write-EnhancedLog -Message "Failed registry settings: $errorCount" -Level "ERROR"
#         Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"

#         # Color-coded summary for the console
#         Write-Host "----------------------------------------" -ForegroundColor White
#         Write-Host "Final Summary Report" -ForegroundColor Cyan
#         Write-Host "Total registry settings processed: $($infoCount + $warningCount + $errorCount)" -ForegroundColor White
#         Write-Host "Successfully applied registry settings: $infoCount" -ForegroundColor Green
#         Write-Host "Skipped registry settings (due to null data): $warningCount" -ForegroundColor Yellow
#         Write-Host "Failed registry settings: $errorCount" -ForegroundColor Red
#         Write-Host "----------------------------------------" -ForegroundColor White

#         # Display the summary table of registry keys and their final states
#         Write-Host "Registry Settings Summary:" -ForegroundColor Cyan
#         $summaryTable | Format-Table -AutoSize

#         # Optionally log the summary to the enhanced log as well
#         foreach ($row in $summaryTable) {
#             Write-EnhancedLog -Message "RegistryPath: $($row.RegistryPath), RegistryName: $($row.RegistryName), Value: $($row.RegistryValue), Status: $($row.Status)" -Level "INFO"
#         }
#     }
# }












# function Apply-RegistrySettings {
#     param (
#         [Parameter(Mandatory = $true)]
#         [hashtable[]]$RegistrySettings,
#         [string]$RegKeyPath
#     )

#     Begin {
#         $infoCount = 0
#         $warningCount = 0
#         $errorCount = 0
#         $summaryTable = [System.Collections.Generic.List[PSCustomObject]]::new()

#         Write-EnhancedLog -Message "Applying registry settings" -Level "INFO"
#     }

#     Process {
#         foreach ($regSetting in $RegistrySettings) {
#             $summaryRow = [PSCustomObject]@{
#                 RegistryPath  = $RegKeyPath
#                 RegistryName  = $regSetting.RegValName
#                 RegistryValue = if ($null -ne $regSetting.RegValData) { $regSetting.RegValData } else { "null" }
#                 Status        = ""
#             }

#             if ($null -ne $regSetting.RegValData) {
#                 Write-EnhancedLog -Message "Setting registry value $($regSetting.RegValName) at $RegKeyPath" -Level "INFO"
#                 $infoCount++

#                 $regParams = @{
#                     RegKeyPath = $RegKeyPath
#                     RegValName = $regSetting.RegValName
#                     RegValType = $regSetting.RegValType
#                     RegValData = $regSetting.RegValData
#                 }

#                 if ($regSetting.RegValData -eq "") {
#                     $regParams.RegValData = ""
#                 }

#                 try {
#                     $setRegistryResult = Set-RegistryValue @regParams

#                     if ($setRegistryResult -eq $true) {
#                         Write-EnhancedLog -Message "Successfully set the registry value: $($regParams.RegValName) at $($regParams.RegKeyPath)" -Level "INFO"
#                         $summaryRow.Status = "Success"
#                     }
#                     else {
#                         Write-EnhancedLog -Message "Failed to set the registry value: $($regParams.RegValName) at $($regParams.RegKeyPath)" -Level "ERROR"
#                         $summaryRow.Status = "Failed"
#                         $errorCount++
#                     }
#                 }
#                 catch {
#                     Write-EnhancedLog -Message "Error setting registry value $($regSetting.RegValName) at $RegKeyPath $($_.Exception.Message)" -Level "ERROR"
#                     $errorCount++
#                     $summaryRow.Status = "Failed"
#                 }
#             }
#             else {
#                 Write-EnhancedLog -Message "Skipping registry value $($regSetting.RegValName) at $RegKeyPath due to null data" -Level "WARNING"
#                 $warningCount++
#                 $summaryRow.Status = "Skipped"
#             }

#             $summaryTable.Add($summaryRow)
#         }
#     }
#     End {
#         # Final Summary Report
#         Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"
#         Write-EnhancedLog -Message "Final Summary Report" -Level "NOTICE"
#         Write-EnhancedLog -Message "Total registry settings processed: $($infoCount + $warningCount + $errorCount)" -Level "INFO"
#         Write-EnhancedLog -Message "Successfully applied registry settings: $infoCount" -Level "INFO"
#         Write-EnhancedLog -Message "Skipped registry settings (due to null data): $warningCount" -Level "WARNING"
#         Write-EnhancedLog -Message "Failed registry settings: $errorCount" -Level "ERROR"
#         Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"

#         # Color-coded summary for the console
#         Write-Host "----------------------------------------" -ForegroundColor White
#         Write-Host "Final Summary Report" -ForegroundColor Cyan
#         Write-Host "Total registry settings processed: $($infoCount + $warningCount + $errorCount)" -ForegroundColor White
#         Write-Host "Successfully applied registry settings: $infoCount" -ForegroundColor Green
#         Write-Host "Skipped registry settings (due to null data): $warningCount" -ForegroundColor Yellow
#         Write-Host "Failed registry settings: $errorCount" -ForegroundColor Red
#         Write-Host "----------------------------------------" -ForegroundColor White

#         # Display the summary table of registry keys and their final states
#         Write-Host "Registry Settings Summary:" -ForegroundColor Cyan
#         $summaryTable | Format-Table -AutoSize

#         # Optionally log the summary to the enhanced log as well
#         foreach ($row in $summaryTable) {
#             Write-EnhancedLog -Message "RegistryPath: $($row.RegistryPath), RegistryName: $($row.RegistryName), Value: $($row.RegistryValue), Status: $($row.Status)" -Level "INFO"
#         }
#     }
# }











function Apply-RegistrySettings {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable[]]$RegistrySettings,
        [string]$RegKeyPath  # Ensure this is passed correctly
    )

    Begin {
        # Initialize counters and summary table
        $infoCount = 0
        $warningCount = 0
        $errorCount = 0
        $summaryTable = [System.Collections.Generic.List[PSCustomObject]]::new()

        Write-EnhancedLog -Message "Applying registry settings" -Level "INFO"
    }

    Process {
        if (-not $RegKeyPath) {
            Write-EnhancedLog -Message "Error: RegKeyPath is not defined." -Level "ERROR"
            throw "RegKeyPath must be defined for Apply-RegistrySettings to work."
        }

        foreach ($regSetting in $RegistrySettings) {
            $summaryRow = [PSCustomObject]@{
                RegistryPath  = $RegKeyPath
                RegistryName  = $regSetting.RegValName
                RegistryValue = if ($null -ne $regSetting.RegValData) { $regSetting.RegValData } else { "null" }
                Status        = ""
            }

            if ($null -ne $regSetting.RegValData) {
                Write-EnhancedLog -Message "Setting registry value $($regSetting.RegValName) at $RegKeyPath" -Level "INFO"
                $infoCount++

                $regParams = @{
                    RegKeyPath = $RegKeyPath
                    RegValName = $regSetting.RegValName
                    RegValType = $regSetting.RegValType
                    RegValData = $regSetting.RegValData
                }

                if ($regSetting.RegValData -eq "") {
                    $regParams.RegValData = ""
                }

                try {
                    $setRegistryResult = Set-RegistryValue @regParams

                    if ($setRegistryResult -eq $true) {
                        Write-EnhancedLog -Message "Successfully set the registry value: $($regParams.RegValName) at $($regParams.RegKeyPath)" -Level "INFO"
                        $summaryRow.Status = "Success"
                    }
                    else {
                        Write-EnhancedLog -Message "Failed to set the registry value: $($regParams.RegValName) at $($regParams.RegKeyPath)" -Level "ERROR"
                        $summaryRow.Status = "Failed"
                        $errorCount++
                    }
                }
                catch {
                    Write-EnhancedLog -Message "Error setting registry value $($regSetting.RegValName) at $RegKeyPath $($_.Exception.Message)" -Level "ERROR"
                    $errorCount++
                    $summaryRow.Status = "Failed"
                }
            }
            else {
                Write-EnhancedLog -Message "Skipping registry value $($regSetting.RegValName) at $RegKeyPath due to null data" -Level "WARNING"
                $warningCount++
                $summaryRow.Status = "Skipped"
            }

            $summaryTable.Add($summaryRow)
        }
    }
    End {
        # Final Summary Report
        Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"
        Write-EnhancedLog -Message "Final Summary Report" -Level "NOTICE"
        Write-EnhancedLog -Message "Total registry settings processed: $($infoCount + $warningCount + $errorCount)" -Level "INFO"
        Write-EnhancedLog -Message "Successfully applied registry settings: $infoCount" -Level "INFO"
        Write-EnhancedLog -Message "Skipped registry settings (due to null data): $warningCount" -Level "WARNING"
        Write-EnhancedLog -Message "Failed registry settings: $errorCount" -Level "ERROR"
        Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"

        # Color-coded summary for the console
        Write-Host "----------------------------------------" -ForegroundColor White
        Write-Host "Final Summary Report" -ForegroundColor Cyan
        Write-Host "Total registry settings processed: $($infoCount + $warningCount + $errorCount)" -ForegroundColor White
        Write-Host "Successfully applied registry settings: $infoCount" -ForegroundColor Green
        Write-Host "Skipped registry settings (due to null data): $warningCount" -ForegroundColor Yellow
        Write-Host "Failed registry settings: $errorCount" -ForegroundColor Red
        Write-Host "----------------------------------------" -ForegroundColor White

        # Display the summary table of registry keys and their final states
        Write-Host "Registry Settings Summary:" -ForegroundColor Cyan
        $summaryTable | Format-Table -AutoSize

        # Optionally log the summary to the enhanced log as well
        foreach ($row in $summaryTable) {
            Write-EnhancedLog -Message "RegistryPath: $($row.RegistryPath), RegistryName: $($row.RegistryName), Value: $($row.RegistryValue), Status: $($row.Status)" -Level "INFO"
        }
    }
}

