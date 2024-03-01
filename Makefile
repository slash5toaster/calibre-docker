SHELL := /usr/bin/env bash

# Docker repository for tagging and publishing
CALIBRE_VERSION ?= 7.5.1
DOCKER_REPO ?= localhost
EXPOSED_PORT ?= 8321

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
	docker run --rm -i \
	-e HADOLINT_FAILURE_THRESHOLD=error \
	-e HADOLINT_IGNORE=DL3042,DL3008,DL3015,DL3048 \
	hadolint/hadolint < Dockerfile$(1)
endef

# HELP
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

envs: ## show the environments
	$(shell echo -e "${CONTAINER_STRING}\n\t${CONTAINER_PROJECT}\n\t${CONTAINER_NAME}\n\t${CONTAINER_TAG}")

docker: ## Build the docker image locally.
	$(call run_hadolint)
	git pull --recurse-submodules;\
	mkdir -vp source/logs/ ; \
	DOCKER_BUILDKIT=1 \
	docker build . \
		-t $(CONTAINER_STRING) \
		--build-arg CALIBRE_VERSION=$(CALIBRE_VERSION) \
		--cache-from $(CONTAINER_STRING) \
		--progress plain \
		--label BUILDDATE=$(LOGDATE) 2>&1 \
	| tee source/logs/build-$(CONTAINER_PROJECT)-$(CONTAINER_NAME)_$(CONTAINER_TAG)-$(LOGDATE).log ;\
	docker inspect $(CONTAINER_STRING) > source/logs/inspect-$(CONTAINER_PROJECT)-$(CONTAINER_NAME)_$(CONTAINER_TAG)-$(LOGDATE).log

setup-multi: ## setup docker multiplatform
	docker buildx create --name buildx-multi-arch ; docker buildx use buildx-multi-arch

docker-multi: ## Multi-platform build.
	$(call setup-multi)
	$(call run_hadolint)
	mkdir -vp  source/logs/ ; \
	docker buildx build --platform linux/amd64,linux/arm64/v8 . \
		-t $(CONTAINER_STRING) \
		--build-arg CALIBRE_VERSION=$(CALIBRE_VERSION) \
		--label org.opencontainers.image.created=$(shell date +%F-%H%M) \
		--cache-from $(CONTAINER_STRING) \
		--progress plain \
		--push

destroy: ## obliterate the local image
	[ "${C_IMAGES}" == "" ] || \
         docker rmi $(CONTAINER_STRING)

apptainer: ## Build an apptainer sif image directly
	apptainer build \
            --build-arg CALIBRE_VERSION=$(CALIBRE_VERSION) \
            /tmp/$(CONTAINER_NAME)_$(CALIBRE_VERSION).sif calibre.def

run: ## run the image
	[ "${C_IMAGES}" ] || \
		make local
	[ "${C_ID}" ] || \
	docker run \
          --rm \
          -it \
          -e TZ=PST8PDT \
          --entrypoint /bin/bash \
          -v "$(shell pwd)":/opt/devel \
          --name $(CONTAINER_NAME) \
          --hostname=$(CONTAINER_NAME) \
          --publish $(EXPOSED_PORT):$(EXPOSED_PORT) \
          $(CONTAINER_STRING)

publish: ## Push server image to remote
	[ "${C_IMAGES}" ] || \
		make local
	@echo 'pushing $(CONTAINER_STRING) to $(DOCKER_REPO)'
	docker push $(CONTAINER_STRING)

docker-lint: ## Check files for errors
	$(call run_hadolint)

# Commands for extracting information on the running container
GET_IMAGES := docker images ${CONTAINER_STRING} --format "{{.ID}}"
GET_CONTAINER := docker ps -a --filter "name=${CONTAINER_NAME}" --no-trunc
GET_ID := ${GET_CONTAINER} --format {{.ID}}
GET_STATUS := ${GET_CONTAINER} --format {{.Status}} | cut -d " " -f1
