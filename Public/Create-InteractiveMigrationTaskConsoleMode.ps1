function Create-InteractiveMigrationTaskConsoleMode {
    <#
    .SYNOPSIS
    Creates a scheduled task to execute the PSADT console migration script using ServiceUI for interactive visibility.

    .DESCRIPTION
    The Create-InteractiveMigrationTaskConsoleMode function creates a scheduled task that launches the `Execute-PSADTConsole.ps1` script via
    ServiceUI in an interactive migration mode. The task runs as NT AUTHORITY\SYSTEM with highest privileges and is triggered at logon, allowing
    visibility of the process running in the SYSTEM context.

    .PARAMETER TaskPath
    The path for the scheduled task.

    .PARAMETER TaskName
    The name of the scheduled task.

    .PARAMETER ServiceUIPath
    The path to the ServiceUI.exe executable.

    .PARAMETER ScriptDirectory
    The directory where the Execute-PSADTConsole.ps1 script is located.

    .PARAMETER ScriptName
    The name of the PowerShell script to execute (e.g., Execute-PSADTConsole.ps1).

    .PARAMETER TaskPrincipalUserId
    The user or group under which the task will run (e.g., "NT AUTHORITY\SYSTEM").

    .PARAMETER TaskRunLevel
    The run level for the task (e.g., "Highest").

    .PARAMETER PowerShellPath
    The path to the PowerShell executable.

    .PARAMETER TaskDescription
    A description for the scheduled task.

    .PARAMETER AtLogOn
    Boolean indicating whether the task should trigger at logon.

    .PARAMETER Delay
    An optional delay to apply before triggering the task.

    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $true)]
        [string]$ServiceUIPath,

        [Parameter(Mandatory = $true)]
        [string]$ScriptDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ScriptName,

        [Parameter(Mandatory = $true)]
        [string]$TaskPrincipalUserId,

        [Parameter(Mandatory = $true)]
        [string]$TaskRunLevel,

        [Parameter(Mandatory = $true)]
        [string]$PowerShellPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskDescription,

        [Parameter(Mandatory = $false)]
        [bool]$AtLogOn = $true,

        [Parameter(Mandatory = $false)]
        [string]$Delay  # No default value is set
    )

    Begin {
        Write-EnhancedLog -Message "Starting Create-InteractiveMigrationTaskConsoleMode function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Unregister the task if it exists
            Unregister-ScheduledTaskWithLogging -TaskName $TaskName

            # Replace the {ScriptPath} placeholder with the full script path
            $fullScriptPath = Join-Path -Path $ScriptDirectory -ChildPath $ScriptName

            # Define the arguments for ServiceUI.exe
            $argList = "-process:explorer.exe $PowerShellPath -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"$fullScriptPath`""
            Write-EnhancedLog -Message "ServiceUI arguments: $argList" -Level "INFO"

            # Create the scheduled task action using ServiceUI
            $actionParams = @{
                Execute  = $ServiceUIPath
                Argument = $argList
            }
            $action = New-ScheduledTaskAction @actionParams

            # Create the scheduled task trigger
            $triggerParams = @{
                AtLogOn = $AtLogOn
            }
            $trigger = New-ScheduledTaskTrigger @triggerParams

            # Apply the delay after creating the trigger, if provided
            if ($PSBoundParameters.ContainsKey('Delay')) {
                $trigger.Delay = $Delay
                Write-EnhancedLog -Message "Setting Delay: $Delay" -Level "INFO"
            }

            # Create the scheduled task principal with SYSTEM context and highest privileges
            $principalParams = @{
                UserId   = $TaskPrincipalUserId  # SYSTEM context
                RunLevel = $TaskRunLevel         # Highest privileges
            }
            $principal = New-ScheduledTaskPrincipal @principalParams

            # Register the scheduled task
            $registerTaskParams = @{
                Principal   = $principal
                Action      = $action
                Trigger     = $trigger
                TaskName    = $TaskName
                Description = $TaskDescription
                TaskPath    = $TaskPath
            }
            Register-ScheduledTask @registerTaskParams

            Write-EnhancedLog -Message "Successfully created the scheduled task: $TaskName" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while creating the interactive migration task: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Create-InteractiveMigrationTaskConsoleMode function" -Level "Notice"
    }
}

# Example usage with splatting
# $CreateInteractiveMigrationTaskConsoleModeParams = @{
#     TaskPath               = "AAD Migration"
#     TaskName               = "PR4B-AADM Launch PSADT for Interactive Migration"
#     ServiceUIPath          = "C:\ProgramData\AADMigration\ServiceUI.exe"
#     ScriptDirectory        = "C:\ProgramData\AADMigration\PSAppDeployToolkit\Toolkit"
#     ScriptName             = "Execute-PSADTConsole.ps1"
#     TaskPrincipalUserId    = "NT AUTHORITY\SYSTEM"  # Run as SYSTEM
#     TaskRunLevel           = "Highest"             # Highest privileges
#     PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
#     TaskDescription        = "AADM Launch PSADT for Interactive Migration Version 1.0"
#     AtLogOn                = $true
#     Delay                  = "PT2H"  # Optional: 2 hours delay
# }

# Create-InteractiveMigrationTaskConsoleMode @CreateInteractiveMigrationTaskConsoleModeParams
