# leet-teach — project tasks.
# `make test` runs the whole suite via the tested runner (scripts/run-tests),
# which discovers every scripts/*_test.sh, aggregates results, and exits
# non-zero if any suite fails.
.DEFAULT_GOAL := test

.PHONY: test
test:
	@./scripts/run-tests
