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

ZOLA ?= ${BIN_DIR}/zola-${ZOLA_VERSION}
${ZOLA}:
	mkdir -p ${BIN_DIR}
	wget -q -O- \
	"https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
	| tar xzf - -C ${BIN_DIR}
	mv ${BIN_DIR}/zola ${ZOLA}

MINIFY ?= ${BIN_DIR}/minify-${MINIFY_VERSION}
${MINIFY}:
	mkdir -p ${BIN_DIR}
	wget -q -O- \
	"https://github.com/tdewolff/minify/releases/download/v${MINIFY_VERSION}/minify_linux_amd64.tar.gz" \
	| tar xzf - -C ${BIN_DIR}
	mv ${BIN_DIR}/minify ${MINIFY}

BIOME_VERSION=1.9.4
BIOME ?= ${BIN_DIR}/biome-${BIOME_VERSION}
${BIOME}:
	mkdir -p ${BIN_DIR}
	wget -q -O ${BIOME} \
	"https://github.com/biomejs/biome/releases/download/cli/v${BIOME_VERSION}/biome-linux-x64"
	chmod +x ${BIOME}

.PHONY: biome
biome: ${BIOME}

.PHONY: format
format:
	${BIOME} format static/ --fix --json-formatter-indent-width=2

.PHONY: build
build: ${ZOLA} ${MINIFY}
	${ZOLA} build ${BUILD_ARGS}
	@# for some reason minified directory creation is getting created after program exit or need to wait
	${MINIFY} -r -a -o minified public && timeout 2 sh -c 'until [ -e minified ]; do echo -n; done;'
	rsync -auv minified/public/ public
	rm public/styles.css

.PHONY: get-date
get-date:
	 @date --iso-8601=seconds
