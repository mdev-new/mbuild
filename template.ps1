# mbuild -f .\template.ps1

$cc = "gcc"

# if you dont use flags you can omit them in the function decl
# (and obviously the exec command too)
function CC($in,$out,$flags) {
	PrintStatus "CC `t$out"
	Exec "$cc -o $out $in @flags"
}

Build @{
	# output       rule  inputs      flags (optional)
	'main.exe' = @('CC', @('main.c'), @('-O3', '-s'));

	# If no rule specified, target is just an alias
	# 'build' is the default rule name to build
	'build' = @('', @('main.exe'));
}