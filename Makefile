.ONESHELL:
.DELETE_ON_ERROR:
.SHELLFLAGS := -eu -c
SHELL := bash
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

PROJECT_DIR := $(PWD)
BIN_DIR := $(PWD)/bin

.PHONY: format
format:
	@biome format static/ --fix --json-formatter-indent-width=2

.PHONY: emoji
emoji:
	@grep -rlE '\s+:\w+:' content/posts/ | xargs -r sed -ri 's, (:[a-z_]+:), {{emoji(i="\1")}},g'

ZOLA_VERSION ?= 0.19.2
ZOLA ?= ${BIN_DIR}/zola-${ZOLA_VERSION}
${ZOLA}:
	@mkdir -p ${BIN_DIR}
	@wget -q -O - \
	"https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
	| tar xzf - -C ${BIN_DIR}
	@mv ${BIN_DIR}/zola ${ZOLA}
	@echo ${ZOLA_VERSION} > .zola_version

.PHONY: build
BUILD_ARGS ?=
build: ${ZOLA}
	${ZOLA} build ${BUILD_ARGS}
