Set-StrictMode -Version Latest

function Write-Log {
    param(
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO',
        [Parameter(Mandatory=$true)][string]$Message
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$ts] [$Level] $Message"
}

function Require-Tool {
    param([Parameter(Mandatory=$true)][string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required tool ''$Name'' not found on PATH."
    }
}

function Load-DotEnv {
    param([string]$Path = ".env")
    if (Test-Path $Path) {
        Get-Content $Path | ForEach-Object {
            if (-not [string]::IsNullOrWhiteSpace($_) -and $_ -notmatch '^#') {
                $kv = $_ -split '=',2
                if ($kv.Count -eq 2) { $env:$($kv[0].Trim()) = $kv[1].Trim() }
            }
        }
        Write-Log INFO "Loaded environment from $Path"
    }
}

function Invoke-CLI {
    param(
        [Parameter(Mandatory=$true)][string]$Command,
        [switch]$DryRun
    )
    if ($DryRun) {
        Write-Log INFO "DRY-RUN: $Command"
        return $null
    }
    $result = & $env:ComSpec /c $Command 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log ERROR "Command failed: $Command"
        throw $result
    }
    return $result
}
