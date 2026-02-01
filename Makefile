SHELL := /usr/bin/env bash

# Docker repository for tagging and publishing
CALIBRE_VERSION ?= 9.0.0

DOCKER_REPO ?= docker.io
EXPOSED_PORT ?= 8321
DOCKER_BIN := $(shell type -p docker || type -p nerdctl || type -p nerdctl.lima || exit)
APPTAINER_BIN := $(shell type -p apptainer || type -p apptainer.lima || type -p singularity || exit)

# info for pushing latest tag when on main branch
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

# Date for log files
LOGDATE := $(shell date +%F-%H%M)

# pull the name from the docker file - these labels *MUST* be set
CONTAINER_PROJECT ?= $(shell grep org.opencontainers.image.vendor Dockerfile | cut -d = -f2 |  tr -d '"\\ ')
CONTAINER_NAME ?= $(shell grep org.opencontainers.image.ref.name Dockerfile  | cut -d = -f2 |  tr -d '"\\ ')
CONTAINER_TAG ?= $(shell grep org.opencontainers.image.version Dockerfile    | cut -d = -f2 |  tr -d '"\\ ')
CONTAINER_STRING ?= $(CONTAINER_PROJECT)/$(CONTAINER_NAME):$(CONTAINER_TAG)

C_ID = $(shell ${GET_ID})
C_STATUS = $(shell ${GET_STATUS})
C_IMAGES = $(shell ${GET_IMAGES})

define run_hadolint
	@echo ''
	@echo '> Dockerfile$(1) ==========='
	$(DOCKER_BIN) run --rm -i \
	-e HADOLINT_FAILURE_THRESHOLD=error \
	-e HADOLINT_IGNORE=DL3042,DL3008,DL3015,DL3048 \
	hadolint/hadolint < Dockerfile$(1)
endef

# Define a different build call for docker
#
ifeq ($(shell basename $(DOCKER_BIN)), docker)
    # Commands/definitions if true (no tab at the start of these lines)
    BUILD_CMD = buildx build
else
    # Commands/definitions if false
    BUILD_CMD = build
endif


# HELP
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# just show the details
#
envs: ## show the environments
	$(info Container String - ${CONTAINER_STRING})
	$(info Project          - ${CONTAINER_PROJECT})
	$(info Name             - ${CONTAINER_NAME})
	$(info Tag is           - ${CONTAINER_TAG})

# Build apptainer/singularity
#
sif: ## Build a sif image directly
	mkdir -vp  source/logs/ ; \
	$(APPTAINER_BIN) build \
            --build-arg CALIBRE_VERSION=$(CALIBRE_VERSION) \
            -F /tmp/$(CONTAINER_NAME)_$(CALIBRE_VERSION).sif \
            calibre.def \
	| tee source/logs/sif-build-$(shell date +%F-%H%M).log

# Build docker/OCI container locally
#
docker: ## Build the docker image locally.
	$(call run_hadolint)
	git pull --recurse-submodules;\
	mkdir -vp source/logs/ ; \
	DOCKER_BUILDKIT=1 \
	$(DOCKER_BIN) $(BUILD_CMD) \
		-t $(CONTAINER_STRING) \
		--build-arg CALIBRE_VERSION=$(CALIBRE_VERSION) \
		--cache-from $(CONTAINER_STRING) \
		--progress plain \
		--label org.opencontainers.image.created=$(shell date +%F-%H%M) 2>&1 \
		-f Dockerfile . \
	| tee source/logs/build-$(CONTAINER_PROJECT)-$(CONTAINER_NAME)_$(CONTAINER_TAG)-$(LOGDATE).log ;\
	$(DOCKER_BIN) inspect $(CONTAINER_STRING) > source/logs/inspect-$(CONTAINER_PROJECT)-$(CONTAINER_NAME)_$(CONTAINER_TAG)-$(LOGDATE).log

# setup-multi: ## setup docker multiplatform
# 	$(DOCKER_BIN) buildx create --name buildx-multi-arch ; $(DOCKER_BIN) buildx use buildx-multi-arch

docker-multi: ## Multi-platform build.
	$(call setup-multi)
	$(call run_hadolint)
	git pull --recurse-submodules; \
	mkdir -vp  source/logs/ ; \
	$(DOCKER_BIN) $(BUILD_CMD) \
        --platform linux/amd64,linux/arm64/v8 \
		--cache-from $(CONTAINER_STRING) \
		-t $(CONTAINER_STRING) \
		--build-arg CALIBRE_VERSION=$(CALIBRE_VERSION) \
		--label org.opencontainers.image.created=$(shell date +%F-%H%M) \
		-f Dockerfile . \
		--progress plain 2>&1 \
	| tee source/logs/build-multi-$(CONTAINER_PROJECT)-$(CONTAINER_NAME)_$(CONTAINER_TAG)-$(LOGDATE).log

destroy: ## obliterate the local image
	[ "${C_IMAGES}" == "" ] || \
         $(DOCKER_BIN) rmi $(CONTAINER_STRING)

run: ## launch shell into the container, with this directory mounted to /opt/devel/
	[ "${C_IMAGES}" ] || \
		make docker
	[ "${C_ID}" ] || \
	$(DOCKER_BIN) run \
          --rm \
          -it \
          -e TZ=PST8PDT \
          --entrypoint /bin/bash \
          -v "$(shell pwd)":/opt/devel \
          --name $(CONTAINER_NAME) \
          --hostname=$(CONTAINER_NAME) \
          --publish $(EXPOSED_PORT):$(EXPOSED_PORT) \
          $(CONTAINER_STRING)

pull: ## Pull Docker image
	@echo 'pulling $(CONTAINER_STRING)'
	$(DOCKER_BIN) pull $(CONTAINER_STRING)

publish: ## Push server image to remote, if on main, publish latest tag
	[ "${C_IMAGES}" ] || \
		make docker
	$(info 'pushing $(CONTAINER_STRING) to $(DOCKER_REPO)')
	$(info $(DOCKER_BIN) push --all-platforms $(CONTAINER_STRING))

# 	publish the latest tag as $(CONTAINER_PROJECT)/$(CONTAINER_NAME):latest
	@if [ "$(GIT_BRANCH)" = "main" ]; then \
		echo "On main branch. Updating 'latest' tag..."; \
		$(DOCKER_BIN) tag $(CONTAINER_STRING) $(CONTAINER_PROJECT)/$(CONTAINER_NAME):latest; \
		$(DOCKER_BIN) push $(CONTAINER_PROJECT)/$(CONTAINER_NAME):latest; \
	else \
		echo "Not on main branch (current: $(GIT_BRANCH)). Skipping 'latest' update."; \
	fi

docker-lint: ## Check files for errors
	$(call run_hadolint)

# Commands for extracting information on the running container
GET_IMAGES := $(DOCKER_BIN) images ${CONTAINER_STRING} --format "{{.ID}}"
GET_CONTAINER := $(DOCKER_BIN) ps -a --filter "name=${CONTAINER_NAME}" --no-trunc
GET_ID := ${GET_CONTAINER} --format {{.ID}}
GET_STATUS := ${GET_CONTAINER} --format {{.Status}} | cut -d " " -f1
