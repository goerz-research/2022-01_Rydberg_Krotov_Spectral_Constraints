using DrWatson
@quickactivate :RydbergKrotovSpectralConstraints

using Pkg
Pkg.instantiate()

println(
"""
Currently active project is: $(projectname())

Path of active project: $(projectdir())
"""
)
