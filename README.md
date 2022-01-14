# 2022-01_Rydberg_Krotov_Spectral_Constraints

This code base is using the [Julia Language](https://julialang.org) and [DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/)
to make a reproducible scientific project named
> RydbergKrotovSpectralConstraints


To (locally) reproduce this project, do the following:

1.  Obtain and initialize the project:

    a. Install Julia. On most platforms, you can simply [download](https://julialang.org/downloads/), unpack it, and maybe make sure that the `julia` executable is in your `$PATH`.

    b. Clone this repository

    c. Start a Julia REPL (run the `julia` exectuable), and do

    ```
    julia> include("path/to/this/project/intro.jl")
    ```

    This will install all necessary packages for you to be able to run the scripts and
    everything should work out of the box, including correctly finding local paths.

    Alternatively, run `make init` from the root project folder.

2.  Reproduce the results

    Run any of the scripts in the `./scripts` subfolder. Use either, e.g. `julia ./scripts/2022-01-09_baseline.jl`, or start a Julia REPL and do, e.g.

    ```
    julia> include("./scripts/2022-01-09_baseline.jl")
    julia> _progmod.main()
    ```

    Running the script inside the REPL has the benefit of avoiding compilation overhead when running multiple scripts.

    You may also run `make` from the project root to run all scripts with missing ouput.

If you want to work on the project with Jupyter notebooks, you must have [IJulia](https://julialang.github.io/IJulia.jl/stable/) installed. The project initialization (`intro.jl`, see above) should have done this for you. Still, check that the kernel is installed correctly. In your terminal,

```
$ jupyter kernelspec list
```

should include a line similar to

```
  julia-1.7                   /home/mgoerz/.local/share/jupyter/kernels/julia-1.7
```

Double check that the `kernel.json` file in that path includes the flag `"--project=@."` (this ensures that the Julia kernel takes into account the settings in the closest `Project.toml` from where any notebook file is stored).
