# Common Pharo project tasks (macOS / Linux).

PHARO_DIR     = pharo-local
PHARO         = ./pharo --headless Pharo.image
TEST_PATTERN  = MetacelloPin.*
PHARO_VERSION = 130
DIR          ?= ../src

.PHONY: help setup load test lint ui check pin lock

help:   ## Show available targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-9s %s\n", $$1, $$2}'

setup:  ## Download a local Pharo image + VM into pharo-local/
	mkdir -p $(PHARO_DIR)
	cd $(PHARO_DIR) && curl -fsSL https://get.pharo.org/64/$(PHARO_VERSION)+vm | bash

load:   ## Load (or reload) the project into the Pharo image
	cd $(PHARO_DIR) && $(PHARO) eval --save "$$(cat ../scripts/load-project.st)"

test:   ## Run tests headless
	cd $(PHARO_DIR) && $(PHARO) test --junit-xml-output '$(TEST_PATTERN)'

lint:   ## Run Pharo lint rules on the loaded project (exit 1 on a finding)
	cd $(PHARO_DIR) && $(PHARO) st --quit ../scripts/lint.st

ui:     ## Open the Pharo GUI (World menu > Library > Metacello Pin)
	cd $(PHARO_DIR) && ./pharo-ui Pharo.image

check:  ## Report unpinned dependencies under DIR (exit 1 if any)
	cd $(PHARO_DIR) && $(PHARO) metacello-pin check $(DIR)

pin:    ## Rewrite BaselineOf* under DIR to commit SHAs
	cd $(PHARO_DIR) && $(PHARO) metacello-pin pin $(DIR)

lock:   ## Write metacello.lock.st for the transitive dependency tree under DIR
	cd $(PHARO_DIR) && $(PHARO) metacello-pin lock $(DIR) --output ../metacello.lock.st
