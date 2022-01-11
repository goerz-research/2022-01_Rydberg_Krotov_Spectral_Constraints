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


struct ScriptRule <: AbstractRule
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
