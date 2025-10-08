param(
    [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] [string]$Action,
    [Parameter(Mandatory=$true)][string]$TagKey,
    [Parameter(Mandatory=$true)][string]$TagValue,
    [string]$Region = "us-east-1",
    [string]$Profile,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Robust helper import
$ScriptDir  = Split-Path -Parent $PSCommandPath
$HelperPath = Join-Path (Join-Path $ScriptDir '..') 'common\helpers.ps1'
. $HelperPath

Require-Tool aws
Load-DotEnv

# Build aws args WITHOUT string interpolation
$awsArgs = @('ec2','describe-instances','--region',$Region)
if ($Profile) { $awsArgs += @('--profile',$Profile) }
# Filters and query as separate args (no "$" next to ":" anywhere)
$awsArgs += @(
  '--filters', ("Name=tag:{0},Values:{1}" -f $TagKey,$TagValue),
  '--query',   "Reservations[].Instances[].{Id:InstanceId,State:State.Name}",
  '--output',  'json'
)

Write-Log INFO ("Finding EC2 instances with tag {0}={1} in {2}" -f $TagKey,$TagValue,$Region)

# Dry-run just shows what we'd call
if ($DryRun) {
    Write-Log INFO ("DRY-RUN: aws {0}" -f ($awsArgs -join ' '))
    exit 0
}

# Execute and parse
$json = & aws @awsArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Log ERROR "aws describe-instances failed"
    throw $json
}

$instances = @()
if ($json) { $instances = $json | ConvertFrom-Json }

if (-not $instances -or $instances.Count -eq 0) {
    Write-Log WARN "No instances matched."
    exit 0
}

# Filter eligible states
$targetIds = @()
foreach ($i in $instances) {
    if ($Action -eq 'Start' -and $i.State -eq 'stopped') { $targetIds += $i.Id }
    if ($Action -eq 'Stop'  -and $i.State -eq 'running') { $targetIds += $i.Id }
}

if ($targetIds.Count -eq 0) {
    Write-Log WARN ("Nothing to {0} (instances already in desired state)." -f $Action)
    exit 0
}

$joined = ($targetIds -join ' ')
Write-Log INFO ("{0} -> {1}" -f $Action, $joined)

# Build start/stop args as arrays too
if ($Action -eq 'Start') {
    $startArgs = @('ec2','start-instances','--instance-ids') + $targetIds + @('--region',$Region)
    if ($Profile) { $startArgs += @('--profile',$Profile) }
    Write-Log INFO ("Executing: aws {0}" -f ($startArgs -join ' '))
    & aws @startArgs | Out-Null
} else {
    $stopArgs = @('ec2','stop-instances','--instance-ids') + $targetIds + @('--region',$Region)
    if ($Profile) { $stopArgs += @('--profile',$Profile) }
    Write-Log INFO ("Executing: aws {0}" -f ($stopArgs -join ' '))
    & aws @stopArgs | Out-Null
}

Write-Log INFO 'Done.'
