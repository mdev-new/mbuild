# (C) MousieDev
# All rights reserved.

# TODO: Make dependency support
# TODO: Multithreading.

#todo log file with hashes of command lines

# Tested & (mostly) works on PS 5.1
# PS7 for some reason rebuilds everytime everything

param (
	[switch]$help = $false,
	[switch]$verbose = $false,
	[switch]$quiet = $false,
	[string]$Cdir = ((Get-Item .).FullName) -join '',
	[string]$file = ".\bcfg.ps1",
	[string]$target = "build"
)

Push-Location $Cdir

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
$printOnlyNormal = if (($quiet -eq $false) -and -not $verbose) {'Out-Default'} else {'Out-Null'}
$total = 0
$done = 1

Set-Alias -Name "Exec" -Value "Invoke-Expression"

# this function took probably longest to write, idk why
function FindDeps($targets,$target) {
	$targets[$target][1] | ForEach-Object {
		if ($targets.keys -contains "$_") {
			Return $_ + (FindDeps $targets $_)
		} else {
			Return $null
		}
	}
}

# returns: false if $base < $fnames
function IsUpToDate([string]$base, [string[]]$fnames) {

	# If the product doesn't exist, we'll definitely need a recompile.
	if([System.IO.File]::Exists($base) -eq $false) {
		return $false
	}

	# This is guaranteed to have a value
	$BaseWriteTime = (Get-Item "$base").LastWriteTime

	$UpToDate = $true
	$fnames | %{
		if([System.IO.File]::Exists("$_") -eq $false) {
			$UpToDate = $false
		} else {
			$UpToDate = $UpToDate -and ($BaseWriteTime -gt ((Get-Item "$_").LastWriteTime))
		}
	}

	return $UpToDate
}

function PrintStatus($text) {
	if (($quiet -eq $false) -or $verbose) {
		Write-Output ("$prefix$text" -f $done, $total, [int](($done/$total) * 100))
	}
}

function Build($targets) {
	if($target -eq '') {
		Write-Output "No target specified."
		Exit
	}

	$build_targets = @()

	#if phony
	if($targets[$target][0] -eq '') {
		$targets[$target][1] | %{
			$deps = FindDeps $targets $_
			if($deps -ne $null) { $build_targets += $deps }
			$build_targets += "$_"
		}
	} else {
		$build_targets += "$target"
	}

	$total = $build_targets.Count

	$bIsUpToDate = $false
	$build_targets | %{
		$bIsUpToDate = IsUpToDate $_ $targets[$_][1]
		if (($targets[$_][0] -ne '') -and ($bIsUpToDate -eq $false)) {
			$flags = @($targets[$_][2], '')[!($targets[$_].Count -eq 3)]
			$inpts = ($targets[$_][1] -join " ")
			& $targets[$_][0] "$inpts" "$_" $flags
			if ($lastexitcode -ne 0) {
				Write-Output "BUILD FAILED"
				Write-Output "Re-run the build with the -v option" | & $printOnlyNormal

				if([System.IO.File]::Exists($_)) { Remove-Item $_ }
				Exit
			}
		} elseif (($targets[$_][0] -eq '') -or ($bIsUpToDate -eq $true)) {
			PrintStatus "ACTUAL`t$_"
		}

		$done++
	}
}

$in_mbuild = $true

# Exec the build file.
. $file
Pop-Location