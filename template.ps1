# (C) zdhroud
# All rights reserved.

# mbuild -f ".\template.ps1" -t "build"

$cc = "tcc"

function CC {
	param($in,$out)

	PrintStatus "CC `t -> $out"
	& $cc -o $out ($in -join " ")
}

$targets = @{
	# output       rule  inputs       phony?
	'main.exe' = @('CC', @('main.c'), $false);

	# If no rule specified, target is just an alias
	'build' = @('', @('main.exe'), $true);
}

# Off to the races!
Build $targets