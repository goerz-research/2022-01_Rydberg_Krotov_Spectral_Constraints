using DrWatson
@quickactivate "RydbergKrotovSpectralConstraints"

include(srcdir("makerules.jl"))

RULES = [
    ScriptRule(
        [datadir("oct", savename("baseline_oct_result", Dict(:iter_stop=>100, :ν_max=>0.0), "jld2"))],
        scriptsdir("2022-01-09_baseline.jl")
    )
]

make(ARGS, RULES)
