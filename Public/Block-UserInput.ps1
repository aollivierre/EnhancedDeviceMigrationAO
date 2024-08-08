function Block-UserInput {
    <#
    .SYNOPSIS
    Blocks or unblocks user input.

    .DESCRIPTION
    The Block-UserInput function blocks or unblocks user input using the user32.dll library. This can be useful during critical operations to prevent user interference.

    .PARAMETER Block
    A boolean value indicating whether to block (true) or unblock (false) user input.

    .EXAMPLE
    $params = @{
        Block = $true
    }
    Block-UserInput @params
    Blocks user input.

    .EXAMPLE
    $params = @{
        Block = $false
    }
    Block-UserInput @params
    Unblocks user input.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Block
    )

    Begin {
        Write-EnhancedLog -Message "Starting Block-UserInput function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            $code = @"
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
"@
            $userInput = Add-Type -MemberDefinition $code -Name Blocker -Namespace UserInput -PassThru

            Write-EnhancedLog -Message "Blocking user input: $Block" -Level "INFO"
            $null = $userInput::BlockInput($Block)
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Block-UserInput function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Block-UserInput function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     Block = $true
# }
# Block-UserInput @params