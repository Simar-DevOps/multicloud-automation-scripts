param(
    [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] [string]$Action,
    [Parameter(Mandatory=$true)][string]$TagKey,
    [Parameter(Mandatory=$true)][string]$TagValue,
    [string]$Region = "us-east-1",
    [string]$Profile,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot/../common/helpers.ps1"

Require-Tool aws
Load-DotEnv

$profileArg = ($Profile) ? "--profile $Profile" : ""

Write-Log INFO "Finding EC2 instances with tag $TagKey=$TagValue in $Region"

$describeCmd = "aws ec2 describe-instances --region $Region $profileArg --filters Name=tag:$TagKey,Values=$TagValue --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name}' --output json"
$json = Invoke-CLI -Command $describeCmd -DryRun:$DryRun

$instances = @()
if (-not $DryRun) {
    $instances = $json | ConvertFrom-Json
}

if ($DryRun) {
    Write-Log INFO "Would query and then $Action instances matching the tag."
    exit 0
}

if (-not $instances -or $instances.Count -eq 0) {
    Write-Log WARN "No instances matched."
    exit 0
}

# Filter eligible states
$targetIds = @()
foreach ($i in $instances) {
    if ($Action -eq "Start" -and $i.State -eq "stopped") { $targetIds += $i.Id }
    if ($Action -eq "Stop"  -and $i.State -eq "running") { $targetIds += $i.Id }
}

if ($targetIds.Count -eq 0) {
    Write-Log WARN "Nothing to $Action (instances already in desired state)."
    exit 0
}

$joined = ($targetIds -join ' ')
Write-Log INFO "$Action -> $joined"

$cmd = if ($Action -eq "Start") {
    "aws ec2 start-instances --instance-ids $joined --region $Region $profileArg"
} else {
    "aws ec2 stop-instances --instance-ids $joined --region $Region $profileArg"
}
Invoke-CLI -Command $cmd -DryRun:$DryRun | Out-Null

Write-Log INFO "Done."
