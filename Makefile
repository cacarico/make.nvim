clear: ## Clear all temp files
	@rm -rf public/

sleep:
	@echo Start sleep
	@sleep 5
	@echo End sleep

.PHONY: help clear

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
