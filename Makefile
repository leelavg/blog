.ONESHELL:
.DELETE_ON_ERROR:
.SHELLFLAGS := -eu -c
SHELL := bash
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

include build.env

PROJECT_DIR := $(PWD)
BIN_DIR := $(PWD)/bin

all: build

.PHONY: format
format:
	@biome format static/ --fix --json-formatter-indent-width=2

.PHONY: emoji
emoji:
	@grep -rlE '\s+:\w+:' content/posts/ | xargs -r sed -ri 's, (:[a-z_]+:), {{emoji(i="\1")}},g'

ZOLA ?= ${BIN_DIR}/zola-${ZOLA_VERSION}
${ZOLA}:
	@mkdir -p ${BIN_DIR}
	@wget -q -O- \
	"https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
	| tar xzf - -C ${BIN_DIR}
	@mv ${BIN_DIR}/zola ${ZOLA}

MINIFY ?= ${BIN_DIR}/minify-${MINIFY_VERSION}
${MINIFY}:
	@mkdir -p ${BIN_DIR}
	@wget -q -O- \
	"https://github.com/tdewolff/minify/releases/download/v${MINIFY_VERSION}/minify_linux_amd64.tar.gz" \
	| tar xzf - -C ${BIN_DIR}
	@mv ${BIN_DIR}/minify ${MINIFY}

.PHONY: build
build: ${ZOLA} ${MINIFY}
	${ZOLA} build ${BUILD_ARGS}
	${MINIFY} -r -a -o minified public

.PHONY: get-date
get-date:
	 @date --iso-8601=seconds
