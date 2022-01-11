using DrWatson
@quickactivate "RydbergKrotovSpectralConstraints"

include(srcdir("makerules.jl"))

RULES = [
    IncludableScriptRule(
        targets=[
            datadir("oct", savename("baseline_oct_result", Dict(:iter_stop=>100, :ν_max=>0.0), "jld2"))
        ],
        script=scriptsdir("2022-01-09_baseline.jl"),
        mod=:BaselineProg
    )
]

make(ARGS, RULES)
