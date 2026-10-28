param(
	[string]$GodotExecutable = "godot",
	[string]$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot ".."))
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path $ProjectPath).Path
$scripts = Get-ChildItem -LiteralPath $projectRoot -Filter "*.gd" -File -Recurse |
	Where-Object { $_.FullName -notmatch "[\\/]\.godot[\\/]" }

foreach ($script in $scripts) {
	$relativePath = $script.FullName.Substring($projectRoot.Length + 1).Replace("\\", "/")
	& $GodotExecutable --headless --path $projectRoot --check-only --script "res://$relativePath"
	if ($LASTEXITCODE -ne 0) {
		throw "GDScript validation failed: $relativePath"
	}
}

& $GodotExecutable --headless --path $projectRoot --script res://tests/test_core_rules.gd
if ($LASTEXITCODE -ne 0) {
	throw "Core smoke tests failed."
}

Write-Output "PROJECT_VALIDATION_PASS"
