include project.env
export


.PHONY: help clean docs lint setup test

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

clean: ## Remove *.tfplan files and directories .terraform/modules and .terraform/plugins
	@./scripts/clean.sh

docs: ## Update documentation
	@./scripts/docs.sh

lint: ## Lint Code
	@./scripts/lint.sh

test: ## Test Code
	@./scripts/test.sh

setup: ## Set up environment
	@./scripts/setup.sh
