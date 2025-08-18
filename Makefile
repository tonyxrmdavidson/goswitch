BATS := test/vendor/bats/bin/bats
# Collect only our .bats files, excluding vendor
BATS_FILES := $(shell find test -type f -name '*.bats' -not -path 'test/vendor/*')
# Let bats-assert find bats-support
BATS_LIB_PATH := test/vendor/bats-support:test/vendor/bats-assert

.PHONY: test
test:
	@echo "Running tests:"
	@echo $(BATS_FILES) | tr ' ' '\n' | sed 's/^/  - /'
	@BATS_LIB_PATH="$(BATS_LIB_PATH)" "$(BATS)" $(BATS_FILES)

SHELLCHECK := shellcheck
SHFMT := shfmt
SOURCES := cmd/goswitch lib/*.sh

.PHONY: lint lint-fix
lint:
	$(SHELLCHECK) -x -S style $(SOURCES)
	$(SHFMT) -d -i 2 -ci $(SOURCES)

lint-fix:
	$(SHFMT) -w -i 2 -ci $(SOURCES)
