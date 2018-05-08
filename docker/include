# Makefile config
#
.DEFAULT = help
.PHONY: $(MAKEFILE_LIST)
SHELL := '/bin/bash'
SCRIPT_BASE   := https://raw.githubusercontent.com/breather/makefiles
SCRIPT_SOURCE := $(SCRIPT_BASE)/master/docker/Makefile
MAKEFILE_DIR  := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

# Include config file
#
CNF   ?= .env.make
-include ${MAKEFILE_DIR}/Makefile.local
-include ${MAKEFILE_DIR}/${CNF}
-include ${MAKEFILE_DIR}/${CNF}.local
-include ${CNF}
-include ${CNF}.local

# Command variables
#
AWS_PROFILE           ?= default

ASSUME                ?= $(shell which assume-role)
ASSUME_CMD            ?= $(ASSUME) $(AWS_PROFILE)
AWS                   ?= $(shell which aws)
AWS_CMD               ?= $(AWS) $(AWS_FLAGS)
ifneq ($(AWS_PROFILE),default)
  AWS_FLAGS             ?= --profile $(AWS_PROFILE)
endif
COMPOSE               ?= $(shell which docker-compose)
COMPOSE_CMD           ?= $(COMPOSE) -f $(COMPOSE_FILE) $(COMPOSE_FLAGS)
COMPOSE_FILE          ?= docker-compose.yml
COMPOSE_FLAGS         ?=
DOCKER                ?= $(shell which docker)
DOCKER_CMD            ?= $(DOCKER) $(DOCKER_FLAGS)
DOCKER_FILE           ?= Dockerfile
DOCKER_FLAGS          ?=
WGET                  ?= $(shell which wget)
WGET_CMD              ?= $(WGET) $(WGET_FLAGS)
WGET_FLAGS            ?=

# Dynamic variables
#
BUILD_DATE            ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
CIRCLE_BRANCH         ?= $(shell git rev-parse --abbrev-ref HEAD)
CIRCLE_BUILD_NUM      ?= 0
CIRCLE_REPOSITORY_URL ?= $(shell git config --get remote.origin.url)
CIRCLE_SHA1            = $(shell git rev-parse HEAD)
WORKING_DIR           ?= $(PWD)
VERSION_FILE          ?= $(WORKING_DIR)/VERSION

# Version detection
#
ifneq ($(wildcard $(VERSION_FILE)),)
  VERSION             ?= $(shell cat $(VERSION_FILE))-$(CIRCLE_BUILD_NUM)
  VERSION_LATEST      ?= $(VERSION)-latest
endif

ifneq ($(wildcard $(WORKING_DIR)/package.json),)
  PKG_VERS            ?= $(shell jq -r .version $(WORKING_DIR)/package.json)
  VERSION             ?= $(PKG_VERS)-$(CIRCLE_BUILD_NUM)
  VERSION_LATEST      ?= $(PKG_VERS)-latest
endif

VERSION               ?= 0.0-$(CIRCLE_BUILD_NUM)
VERSION_LATEST        ?= latest

# Overwritable variables
#
ORG                   ?= breather
MAINTAINER            ?= platform+docker@breather.com
NAME                  ?= $(basename $(PWD))
TAG_PREFIX            ?=
TAG                   ?= $(VERSION)
TAG_BUILD             ?= $(CIRCLE_SHA1)
TAG_LATEST            ?= $(VERSION_LATEST)

# Constructed variables
#
IMG                   ?= $(ORG)/$(NAME)
IMG_BUILD             ?= $(IMG):$(TAG_PREFIX)$(TAG_BUILD)
IMG_CACHE             ?= $(IMG_BUILD) $(IMG_BUILDER) $(IMG_LATEST)
IMG_TAGGED            ?= $(IMG):$(TAG_PREFIX)$(TAG)
IMG_TARGET            ?= $(IMG_BUILD)-$(DOCKER_TARGET)
IMG_LATEST            ?= $(IMG):$(TAG_PREFIX)$(TAG_LATEST)

# Targets
#
help: ## Show this help message.
	$(info Docker image builder)
	$(info )
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

exec: ## Assume an aws role and execute CMD="cmd args"
	$(ASSUME_CMD) $(CMD)

build: build.target build.image ## Build docker container and optional target

build.image: ## Build docker container
	cd $(WORKING_DIR); $(DOCKER_CMD) build \
		$(foreach var,$(IMG_CACHE),--cache-from $(var)) \
		--file $(DOCKER_FILE) \
		--label maintainer=$(MAINTAINER) \
		--label org.label-schema.build-date=$(BUILD_DATE) \
		--label org.label-schema.name=$(NAME) \
		--label org.label-schema.vcs-ref=$(CIRCLE_SHA1) \
		--label org.label-schema.vcs-url=$(CIRCLE_REPOSITORY_URL) \
		--label org.label-schema.vcs-branch=$(CIRCLE_BRANCH) \
		--label org.label-schema.version=$(VERSION) \
		--tag $(IMG_BUILD) \
		$(BUILD_ARGS) \
		$(WORKING_DIR)

build.target: ## Build docker target if defined
ifdef DOCKER_TARGET
	cd $(WORKING_DIR); $(DOCKER_CMD) build \
		$(foreach var,$(IMG_CACHE),--cache-from $(var)) \
		--file $(DOCKER_FILE) \
		--tag $(IMG_TARGET) \
		--target $(DOCKER_TARGET) \
		$(BUILD_ARGS) \
		$(WORKING_DIR)
endif

compose: ## Wrap docker-compose with assume-role, requires -e COMPOSE_FLAGS=""
	$(ASSUME_CMD) $(COMPOSE_CMD)

login: ## Login to repository
ifeq ($(DOCKER_NOLOGIN),)
ifneq (,$(findstring amazonaws.com,$(ORG)))
	$$($(AWS_CMD) ecr get-login --no-include-email)
else
	@$(DOCKER_CMD) login --username $(DOCKER_USER) --password $(DOCKER_PASS)
endif
endif

pull: login ## Pull tagged docker image from repository
	$(DOCKER_CMD) pull $(PULL_FLAGS) $(IMG_TAGGED)

push: login ## Push tagged docker image to repository
	$(DOCKER_CMD) push $(PUSH_FLAGS) $(IMG_TAGGED)

push.latest:
	$(DOCKER_CMD) push $(PUSH_FLAGS) $(IMG_LATEST)

tag: ## Tag build image
ifneq ($(IMG_BUILD),$(IMG_TAGGED))
	$(DOCKER_CMD) tag $(IMG_BUILD) $(IMG_TAGGED)
endif

tag.latest:
	$(DOCKER_CMD) tag $(IMG_BUILD) $(IMG_LATEST)

print.env:  ## Print current environment
	@env

print.tag: ## Print current build tag
	@echo $(TAG_BUILD)

print.version: ## Print current version
	@echo $(VERSION)

print.version.latest: ## Print current version
	@echo $(VERSION_LATEST)

self.upgrade: ## Upgrade this instance of the Makefile
	$(WGET_CMD) --unlink -q $(SCRIPT_SOURCE) -O Makefile
