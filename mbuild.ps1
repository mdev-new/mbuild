# (C) MousieDev
# All rights reserved.

# TODO: Make dependency support

param (
	[switch]$help = $false,
	[switch]$verbose = $false,
	[switch]$quiet = $false,
	[string]$Cdir = ((Get-Item .).FullName) -join '',
	[string]$file = ".\bcfg.ps1",
	[string]$target = ""
)

Set-PSDebug -Trace 0
pushd $Cdir

if ($help) {
	Write-Output "MousieBuild v0.3"
	Write-Output "Usage: .\build.ps1 [-hqv] [-C <dirpath>] [-f <filename>] [-t <name>]"
	Write-Output "`t -h; -help: Get this message."
	Write-Output "`t -q; -quiet: Be quiet."
	Write-Output "`t -v; -verbose: Print everything."
	Write-Output "`t -C <dirpath>; -Cdir <dirpath>: Change to <dirpath> before running."
	Write-Output "`t -f <filename>; -file <filename>: Set build config filename. (Default is .\bcfg.ps1)"
	Write-Output "`t -t <name>; -target <name>: Set aditional target to build. (For example phony targets)"
	Exit
}

# Command output only on verbose mode
$printVerbose = if ($verbose) {'Out-Default'} else {'Out-Null'}
$printNormal = if ($quiet -eq $false) {'Out-Default'} else {'Out-Null'}
$total = 0
$done = 1

New-Item -ItemType Directory -Force -Path "tmp" | & $printVerbose

$build_targets = New-Object 'System.Collections.Generic.List[string]'

function RecursiveTargetWalk($target) {
	$targets[$target][1] | ForEach-Object {
		if ($targets.keys -contains "$_") {
			$build_targets.Insert(0,$_)
			RecursiveTargetWalk $_
		} else { Return }
	}
}

# returns: false if $base < $fnames
function IsUpToDate([string]$base, [string[]]$fnames){
	$BaseWriteTime = (Get-Item "$base" -ErrorAction SilentlyContinue).LastWriteTime

	$Results = @();

	$fnames | %{
		#Write-Host $BaseWriteTime (Get-Item "$_").LastWriteTime
		$Results += ($BaseWriteTime -ge ((Get-Item "$_").LastWriteTime))
	}

	# AND all the results together
	$UpToDate = $true
	$Results | % {
		$UpToDate = $UpToDate -and $_
	}

	return $UpToDate
}

function PrintStatus($text) {
	if (($quiet -eq $false) -or $verbose) { Write-Output ("$prefix$text" -f $done,$total,[int](($done/$total) * 100) ) }
}

function Build($targets) {
	$build_targets.Add($target)

	RecursiveTargetWalk $target
	$total = $build_targets.Count

	$build_targets | %{
		if ($targets[$_][0] -eq '' -or $targets[$_][2] -eq $true) { $total--; }
	}

	$build_targets | %{
		if ($targets[$_][2] -ne $true -and (IsUpToDate $_ $targets[$_][1] ) -eq $false) {
			& $targets[$_][0] $targets[$_][1] $_
			if ($lastexitcode -ne 0) {
				Write-Output "BUILD FAILED"
				Write-Output "Re-run the build with the -v option" | & $printNormal
				
				if([System.IO.File]::Exists($_)) { del $_ }
				Exit
			}
		} elseif ($targets[$_][2] -ne $true) {
			PrintStatus "ACTUAL`t$_"
		} elseif ($targets[$_][0] -ne '') {
			& $targets[$_][0] $targets[$_][1] $_
		}

		$done++
	}
}

# Exec the build file.
. $file
popd