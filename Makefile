.PHONY: init help devrepl clean .FORCE

.DEFAULT_GOAL := all

define PRINT_HELP_JLSCRIPT
rx = r"^([a-z0-9A-Z_-]+):.*?##[ ]+(.*)$$"
for line in eachline()
    m = match(rx, line)
    if !isnothing(m)
        target, help = m.captures
        println("$$(rpad(target, 20)) $$help")
    end
end
endef
export PRINT_HELP_JLSCRIPT


help:  ## Show this help
	@julia -e "$$PRINT_HELP_JLSCRIPT" < $(MAKEFILE_LIST)

init: ## Initialize the project
	julia intro.jl

.initialized: intro.jl Project.toml
	julia $<

.make_jl: make.jl .initialized .FORCE
	julia $<

devrepl: .initialized  ## Start an interactive REPL
	julia --threads=auto --startup-file=yes -e 'using DrWatson; @quickactivate "RydbergKrotovSpectralConstraints"' -i

all: .make_jl  ## Ensure all output data

clean:  ## Remove generated files
	julia make.jl clean

distclean: clean  ## Restore clean repository state
	rm .initialized
