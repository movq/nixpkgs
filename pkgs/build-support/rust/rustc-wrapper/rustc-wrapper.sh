#!@shell@

defaultSysroot=(@sysroot@)
effectiveTarget="@defaultTarget@"
declare -a params=("$@")

# Parse enough of rustc's CLI to determine sysroot and effective target.
declare -i n=0
nParams=${#params[@]}
while (("$n" < "$nParams")); do
    p=${params[n]}
    v=${params[n + 1]:-} # handle `p` being last one
    n+=1

    case "$p" in
        --sysroot)
            defaultSysroot=()
            # Skip the value passed to --sysroot.
            n+=1
            ;;
        --sysroot=*)
            defaultSysroot=()
            ;;
        --target)
            if [ -n "$v" ]; then
                effectiveTarget=$v
                # Skip the value passed to --target.
                n+=1
            fi
            ;;
        --target=*)
            effectiveTarget="${p#*=}"
            ;;
        --)
            break
            ;;
    esac
done

extraBefore=(@defaultArgs@ "${defaultSysroot[@]}")
# Default x86_64 toolchains to v3, but only when rustc is actually targeting x86_64.
if [[ "@enableX86_64V3TargetCpu@" == 1 ]] && [[ "$effectiveTarget" == x86_64-* ]]; then
    extraBefore+=(-C target-cpu=x86-64-v3)
fi
extraAfter=($@extraFlagsVar@)

# Optionally print debug info.
if (( "${NIX_DEBUG:-0}" >= 1 )); then
    echo "extra flags before to @prog@:" >&2
    printf "  %q\n" "${extraBefore[@]}" >&2
    echo "original flags to @prog@:" >&2
    printf "  %q\n" "$@" >&2
    echo "extra flags after to @prog@:" >&2
    printf "  %q\n" "${extraAfter[@]}" >&2
fi

exec @prog@ "${extraBefore[@]}" "$@" "${extraAfter[@]}"
