using Pkg
Pkg.add("DrWatson")
Pkg.add("Revise")

using DrWatson
@quickactivate :RydbergKrotovSpectralConstraints

Pkg.instantiate()

println(
"""
Currently active project is: $(projectname())

Path of active project: $(projectdir())
"""
)

touch(joinpath(@__DIR__, ".initialized"))
