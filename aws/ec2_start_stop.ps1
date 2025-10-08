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

# Build describe args (NO interpolation)
$awsArgs = @('ec2','describe-instances','--region',$Region)
if ($Profile) { $awsArgs += @('--profile',$Profile) }
$filter = ('Name=tag:{0},Values:{1}' -f $TagKey,$TagValue)
$jmes   = 'Reservations[].Instances[].{Id:InstanceId,State:State.Name}'
$awsArgs += @('--filters', $filter, '--query', $jmes, '--output', 'json')

Write-Log INFO ("Finding EC2 instances with tag {0}={1} in {2}" -f $TagKey,$TagValue,$Region)

if ($DryRun) {
    Write-Log INFO ("DRY-RUN: aws {0}" -f ($awsArgs -join ' '))
    exit 0
}

$json = & aws @awsArgs 2>&1
if ($LASTEXITCODE -ne 0) { Write-Log ERROR 'aws describe-instances failed'; throw $json }

$instances = @()
if ($json) { $instances = $json | ConvertFrom-Json }

if (-not $instances -or $instances.Count -eq 0) { Write-Log WARN 'No instances matched.'; exit 0 }

$targetIds = @()
foreach ($i in $instances) {
    if ($Action -eq 'Start' -and $i.State -eq 'stopped') { $targetIds += $i.Id }
    if ($Action -eq 'Stop'  -and $i.State -eq 'running')  { $targetIds += $i.Id }
}

if ($targetIds.Count -eq 0) { Write-Log WARN ("Nothing to {0} (already in desired state)." -f $Action); exit 0 }

Write-Log INFO ("{0} -> {1}" -f $Action, ($targetIds -join ' '))

if ($Action -eq 'Start') {
    $startArgs = @('ec2','start-instances','--instance-ids') + $targetIds + @('--region',$Region)
    if ($Profile) { $startArgs += @('--profile',$Profile) }
    & aws @startArgs | Out-Null
} else {
    $stopArgs = @('ec2','stop-instances','--instance-ids') + $targetIds + @('--region',$Region)
    if ($Profile) { $stopArgs += @('--profile',$Profile) }
    & aws @stopArgs | Out-Null
}

Write-Log INFO 'Done.'
