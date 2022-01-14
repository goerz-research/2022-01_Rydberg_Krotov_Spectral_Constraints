using Pkg
Pkg.activate()
Pkg.add("DrWatson")
Pkg.add("Revise")
Pkg.add("IJulia")
Pkg.activate(@__DIR__)
Pkg.instantiate()

using DrWatson
@quickactivate :RydbergKrotovSpectralConstraints

println(
"""
Currently active project is: $(projectname())

Path of active project: $(projectdir())
"""
)

touch(joinpath(@__DIR__, ".initialized"))
