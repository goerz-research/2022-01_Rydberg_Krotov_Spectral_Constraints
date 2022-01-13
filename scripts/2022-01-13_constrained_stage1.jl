module OctStage1Prog

using DrWatson
@quickactivate "RydbergKrotovSpectralConstraints"

using RydbergKrotovSpectralConstraints: run_oct, ns

using LinearAlgebra
BLAS.set_num_threads(1)

using QuantumControl

using Plots
unicodeplots()


function _convert_freq_to_float(s::String)
    if endswith(s, "GHz")
        return parse(Float64, s[1:end-3]) * (1/ns)
    else
        @warn("Value $s taken to be in internal units. Consider '$sGHz' instead")
        return parse(s)
    end
end

_convert_freq_to_float(v::Float64) = v


function main(args=ARGS; λₐ=1e12, iter_stop=100, kwargs...)
    # This takes ν_max as a command-line argument. Use "GHz" suffix, e.g.,
    # `julia scripts/2022-01-13_constrained_stage1.jl 0.7GHz`
    #
    # For interactive usage, call `main([ν_max])`. In interactive mode only,
    # we can also play around with the Krotov inverse step width λₐ, and other
    # kwargs that will be forwarded to run_oct
    ν_max = _convert_freq_to_float(args[1])
    oct_args = Dict(
        :iter_stop=>iter_stop,
        :ν_max=>ν_max,
        :λₐ=>λₐ,
    )
    prefix = "oct_result"
    outdir = datadir("oct", "stage1")
    @produce_or_load(outdir, oct_args, prefix=prefix) do oct_args
        oct_result = run_oct(;oct_args..., kwargs...)
        @strdict ν_min=0.0 ν_max oct_result
    end
end


end

_progmod = OctStage1Prog
if abspath(PROGRAM_FILE) == @__FILE__
    _progmod.main()
end
