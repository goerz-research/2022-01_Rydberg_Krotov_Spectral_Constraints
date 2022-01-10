module BaselineProg

using DrWatson
@quickactivate "RydbergKrotovSpectralConstraints"

using RydbergKrotovSpectralConstraints: run_oct

using LinearAlgebra
BLAS.set_num_threads(1)

using QuantumControl

using Plots
unicodeplots()


function main()
    args = Dict(
        :iter_stop=>100,
        :ν_max=>0.0,
    )
    prefix = "baseline_oct_result"
    @produce_or_load(datadir("oct"), args, prefix=prefix) do args
        oct_result = run_oct(;args...)
        @strdict oct_result
    end
end


end

BaselineProg.main()
