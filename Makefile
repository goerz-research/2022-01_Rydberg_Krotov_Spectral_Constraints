.PHONY: init help devrepl .FORCE

.DEFAULT_GOAL := all

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
    match = re.match(r'^([a-z0-9A-Z_-]+):.*?## (.*)$$', line)
    if match:
        target, help = match.groups()
        print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:  ## Show this help
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

init: ## Initialize the project
	julia intro.jl

.initialized: intro.jl Project.toml
	julia $<

.make_jl: make.jl .initialized .FORCE
	julia $<

devrepl: .initialized  ## Start an interactive REPL
	julia --threads=auto --startup-file=yes -e 'using DrWatson; @quickactivate "RydbergKrotovSpectralConstraints"' -i

all: .make_jl ## Ensure all output data
