function Download-OneDriveSetup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ODSetupUri,

        [Parameter(Mandatory = $true)]
        [string]$ODSetupPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Download-OneDriveSetup function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Invoke-WebRequest -Uri $ODSetupUri -OutFile $ODSetupPath
            Write-EnhancedLog -Message "Downloaded OneDrive setup to $ODSetupPath" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while downloading OneDrive setup: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Download-OneDriveSetup function" -Level "Notice"
    }
}

function Get-OneDriveSetupVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ODSetupPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-OneDriveSetupVersion function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            $ODSetupVersion = (Get-ChildItem -Path $ODSetupPath).VersionInfo.FileVersion
            Write-EnhancedLog -Message "OneDrive setup version: $ODSetupVersion" -Level "INFO"
            return $ODSetupVersion
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while getting OneDrive setup version: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-OneDriveSetupVersion function" -Level "Notice"
    }
}


function Get-InstalledOneDriveVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ODRegKey
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-InstalledOneDriveVersion function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            $InstalledVer = if (Test-Path -Path $ODRegKey) {
                Get-ItemPropertyValue -Path $ODRegKey -Name Version
            } else {
                [System.Version]::new("0.0.0.0")
            }
            Write-EnhancedLog -Message "Installed OneDrive version: $InstalledVer" -Level "INFO"
            return $InstalledVer
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while getting installed OneDrive version: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-InstalledOneDriveVersion function" -Level "Notice"
    }
}


function Install-OneDriveSetup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ODSetupPath,

        [Parameter(Mandatory = $true)]
        [string]$SetupArgumentList
    )

    Begin {
        Write-EnhancedLog -Message "Starting Install-OneDriveSetup function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Installing OneDrive setup" -Level "INFO"
            Start-Process -FilePath $ODSetupPath -ArgumentList $SetupArgumentList -Wait -NoNewWindow
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while installing OneDrive setup: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Install-OneDriveSetup function" -Level "Notice"
    }
}


function Perform-KFMSync {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OneDriveExePath,

        [Parameter(Mandatory = $true)]
        [string]$ScheduledTaskName,

        [Parameter(Mandatory = $true)]
        [string]$ScheduledTaskDescription
    )

    Begin {
        Write-EnhancedLog -Message "Starting Perform-KFMSync function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Performing KFM sync" -Level "INFO"
            $ODProcess = Get-Process -Name OneDrive -ErrorAction SilentlyContinue

            if ($ODProcess) {
                $ODProcess | Stop-Process -Confirm:$false -Force
                Start-Sleep -Seconds 5

                Unregister-ScheduledTaskWithLogging -TaskName $ScheduledTaskName

                $CreateOneDriveRemediationTaskParams = @{
                    OneDriveExePath           = $OneDriveExePath
                    ScheduledTaskName         = $ScheduledTaskName
                    ScheduledTaskDescription  = $ScheduledTaskDescription
                }
                
                Create-OneDriveRemediationTask @CreateOneDriveRemediationTaskParams
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while performing KFM sync: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Perform-KFMSync function" -Level "Notice"
    }
}


function Install-OneDrive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MigrationPath,

        [Parameter(Mandatory = $false)]
        [bool]$OneDriveKFM = $false,

        [Parameter(Mandatory = $true)]
        [string]$ODSetupUri,

        [Parameter(Mandatory = $true)]
        [string]$ODSetupFile,

        [Parameter(Mandatory = $true)]
        [string]$ODRegKey,

        [Parameter(Mandatory = $true)]
        [string]$OneDriveExePath,

        [Parameter(Mandatory = $true)]
        [string]$ScheduledTaskName,

        [Parameter(Mandatory = $true)]
        [string]$ScheduledTaskDescription,

        [Parameter(Mandatory = $true)]
        [string]$SetupArgumentList
    )

    Begin {
        Write-EnhancedLog -Message "Starting Install-OneDrive function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        $ODSetupPath = Join-Path -Path $MigrationPath -ChildPath $ODSetupFile
        $ODSetupVersion = $null
    }

    Process {
        try {
            if (-not (Test-Path -Path $ODSetupPath)) {
                Download-OneDriveSetup -ODSetupUri $ODSetupUri -ODSetupPath $ODSetupPath
            }

            $ODSetupVersion = Get-OneDriveSetupVersion -ODSetupPath $ODSetupPath
            $InstalledVer = Get-InstalledOneDriveVersion -ODRegKey $ODRegKey

            if (-not $InstalledVer -or ([System.Version]$InstalledVer -lt [System.Version]$ODSetupVersion)) {
                Install-OneDriveSetup -ODSetupPath $ODSetupPath -SetupArgumentList $SetupArgumentList
            } elseif ($OneDriveKFM) {
                Perform-KFMSync -OneDriveExePath $OneDriveExePath -ScheduledTaskName $ScheduledTaskName -ScheduledTaskDescription $ScheduledTaskDescription
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Install-OneDrive function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Install-OneDrive function" -Level "Notice"
    }
}


# $InstallOneDriveParams = @{
#     MigrationPath              = "C:\ProgramData\AADMigration"
#     OneDriveKFM                = $true
#     ODSetupUri                 = "https://go.microsoft.com/fwlink/?linkid=844652"
#     ODSetupFile                = "Files\OneDriveSetup.exe"
#     ODRegKey                   = "HKLM:\SOFTWARE\Microsoft\OneDrive"
#     OneDriveExePath            = "C:\Program Files\Microsoft OneDrive\OneDrive.exe"
#     ScheduledTaskName          = "OneDriveRemediation"
#     ScheduledTaskDescription   = "Restart OneDrive to kick off KFM sync"
#     ScheduledTaskArgumentList  = ""
#     SetupArgumentList          = "/allusers"
# }

# Install-OneDrive @InstallOneDriveParams