# NOTE: This source file is not included in RydbergKrotovSpectralConstraints.jl
# It is intended to be included directly in `make.jl` in the project root
using DrWatson: projectdir
using LibGit2: GitRepo, GitTree


function targets_up_to_date(targets, dependencies)
    deptime = maximum([mtime(d) for d in dependencies])
    for target in targets
        if mtime(target) < deptime
            return false
        end
    end
    return true
end


abstract type AbstractRule end


struct IncludableScriptRule <: AbstractRule
    targets::Vector{String}
    script::String
    mod::Union{Symbol, Nothing}
    main::Union{Symbol, Nothing}
    args::Vector{String}
    function IncludableScriptRule(
        targets, script; mod=nothing, main=:main, args=String[]
    )
        new(targets, script, mod, main, args)
    end
end


function IncludableScriptRule(;
    targets, script, mod=nothing, main=:main, args=String[]
)
    IncludableScriptRule(targets, script, mod=mod, main=main, args=args)
end


function eval_rule(r::IncludableScriptRule)
    if !targets_up_to_date(r.targets, [r.script])
        mod = r.mod
        main = r.main
        args = r.args
        if isnothing(main)
            # The assumption is that the script is written in such a way that
            # simply including it runs it. There is no way to pass arguments
            if length(args) > 0
                error("Passing arguments to $(r.script) requires a main function")
            end
            @info "Running $(r.script) to produce $(r.targets)"
            include(r.script)
        else
            if isnothing(mod)
                @info "Running $(r.script):$main($args) to produce $(r.targets)"
                include(r.script)
                @eval $main($args)
            else
                @info "Running $(r.script):$mod.$main($args) to produce $(r.targets)"
                include(r.script)
                @eval $mod.$main($args)
            end
        end
    else
        @info "$(r.targets): OK"
    end
end


function clean_rule(r::AbstractRule, tree::GitTree)
    for target in r.targets
        # we remove all target files that haven't been committed to git
        if !haskey(tree, relpath(target, projectdir()))
            @info "Removing $target"
            rm(target, force=true)
        end
    end
end


function make(args, rules)
    if !isempty(args) && args[end] == "clean"
        repo = GitRepo(projectdir())
        tree = GitTree(repo,"HEAD^{tree}")
        for rule in rules
            clean_rule(rule, tree)
        end
        rm(projectdir(".make_jl"), force=true)
    else
        for rule in rules
            eval_rule(rule)
        end
        touch(projectdir(".make_jl"))
    end
end
