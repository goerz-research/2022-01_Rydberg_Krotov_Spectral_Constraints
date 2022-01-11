# NOTE: This source file is not included in RydbergKrotovSpectralConstraints.jl
# It is intended to be included directly in `make.jl` in the project root


function targets_up_to_date(targets, dependencies)
    deptime = maximum([mtime(d) for d in dependencies])
    for target in targets
        if mtime(target) < deptime
            return false
        end
    end
    return true
end


struct ScriptRule
    # targets are produced by running script without args
    targets::Vector{String}
    script::String
end


function eval_rule(r::ScriptRule)
    if !targets_up_to_date(r.targets, [r.script])
        @info "Running $(r.script) to produce $(r.targets)"
        include(r.script)
    else
        @info "$(r.targets): OK"
    end
end
