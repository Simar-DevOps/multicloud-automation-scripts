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

$profileArg = if ($Profile) { "--profile $Profile" } else { "" }

Write-Log INFO ("Finding EC2 instances with tag {0}={1} in {2}" -f $TagKey,$TagValue,$Region)

$filter     = ("Name=tag:{0},Values:{1}" -f $TagKey,$TagValue)
# Escape curly braces in the JMESPath projection used by -f by doubling them
$jmesQuery  = "Reservations[].Instances[].{{Id:InstanceId,State:State.Name}}"
$describeCmd = ("aws ec2 describe-instances --region {0} {1} --filters {2} --query '{3}' --output json" -f $Region,$profileArg,$filter,$jmesQuery)

$json = Invoke-CLI -Command $describeCmd -DryRun:$DryRun

$instances = @()
if (-not $DryRun) {
    $instances = $json | ConvertFrom-Json
}

if ($DryRun) {
    Write-Log INFO ("Would query and then {0} instances matching the tag." -f $Action)
    exit 0
}

if (-not $instances -or $instances.Count -eq 0) {
    Write-Log WARN "No instances matched."
    exit 0
}

$targetIds = @()
foreach ($i in $instances) {
    if ($Action -eq "Start" -and $i.State -eq "stopped") { $targetIds += $i.Id }
    if ($Action -eq "Stop"  -and $i.State -eq "running") { $targetIds += $i.Id }
}

if ($targetIds.Count -eq 0) {
    Write-Log WARN ("Nothing to {0} (instances already in desired state)." -f $Action)
    exit 0
}

$joined = ($targetIds -join ' ')
Write-Log INFO ("{0} -> {1}" -f $Action, $joined)

$cmd = if ($Action -eq "Start") {
    ("aws ec2 start-instances --instance-ids {0} --region {1} {2}" -f $joined,$Region,$profileArg)
} else {
    ("aws ec2 stop-instances --instance-ids {0} --region {1} {2}" -f $joined,$Region,$profileArg)
}
Invoke-CLI -Command $cmd -DryRun:$DryRun | Out-Null

Write-Log INFO "Done."
