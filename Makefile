.ONESHELL:
.DELETE_ON_ERROR:
.SHELLFLAGS := -eu -c
SHELL := bash
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.PHONY: format
format:
	@biome format static/ --fix --json-formatter-indent-width=2

.PHONY: emoji
emoji:
	@grep -rlE '\s+:\w+:' content/posts/ | xargs -r sed -ri 's, (:[a-z_]+:), {{e(i="\1")}},g'
