
function Remove-MigrationFiles {
    <#
    .SYNOPSIS
    Removes specified directories used during the migration process.
  
    .DESCRIPTION
    The Remove-MigrationFiles function deletes specified directories used during the migration process, leaving the log folder intact.
  
    .PARAMETER Directories
    An array of directories to be removed.
  
    .EXAMPLE
    $params = @{
        Directories = @(
            "C:\ProgramData\AADMigration\Files",
            "C:\ProgramData\AADMigration\Scripts",
            "C:\ProgramData\AADMigration\Toolkit"
        )
    }
    Remove-MigrationFiles @params
    Removes the specified directories.
    #>
  
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Directories
    )
  
    Begin {
        Write-EnhancedLog -Message "Starting Remove-MigrationFiles function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }
  
    Process {
        try {
            foreach ($directory in $Directories) {
                if (Test-Path -Path $directory) {
                    Write-EnhancedLog -Message "Removing directory: $directory" -Level "INFO"
                    Remove-Item -Path $directory -Recurse -Force -ErrorAction Stop
                    Write-EnhancedLog -Message "Successfully removed directory: $directory" -Level "INFO"
                }
                else {
                    Write-EnhancedLog -Message "Directory not found: $directory" -Level "WARNING"
                }
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Remove-MigrationFiles function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }
  
    End {
        Write-EnhancedLog -Message "Exiting Remove-MigrationFiles function" -Level "Notice"
    }
  }
  
  # # Example usage
  # $params = @{
  #   Directories = @(
  #       "C:\ProgramData\AADMigration\Files",
  #       "C:\ProgramData\AADMigration\Scripts",
  #       "C:\ProgramData\AADMigration\Toolkit"
  #   )
  # }
  # Remove-MigrationFiles @params