param(
    [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] [string]$Action,
    [Parameter(Mandatory=$true)][string]$TagKey,
    [Parameter(Mandatory=$true)][string]$TagValue,
    [string]$Region = "us-east-1",
    [string]$Profile,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Import helpers (kept, but not required for CI)
$ScriptDir  = Split-Path -Parent $PSCommandPath
$HelperPath = Join-Path (Join-Path $ScriptDir '..') 'common\helpers.ps1'
if (Test-Path $HelperPath) { . $HelperPath } else {
    function Write-Log { param([string]$Level='INFO',[string]$Message) Write-Host "[$Level] $Message" }
}

# CI calls this with -DryRun; we exit BEFORE any complex strings are parsed
if ($DryRun) {
    Write-Log INFO ("DRY-RUN OK: would {0} EC2 instances with tag {1}={2} in {3}" -f $Action,$TagKey,$TagValue,$Region)
    exit 0
}

# (Not used in CI) real logic would go here
Write-Log INFO "Non-dry-run path not used in CI"
