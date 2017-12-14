# Makefile config
#
.DEFAULT = help
.PHONY: $(MAKEFILE_LIST)
SHELL := '/bin/bash'
SCRIPT_BASE   := https://raw.githubusercontent.com/breather/makefiles
SCRIPT_SOURCE := $(SCRIPT_BASE)/master/docker/Makefile

# Include config file
#
CNF   ?= .env.make
-include ${CNF}
-include ${CNF}.local
-include Makefile.local

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

# Version detection
#
ifneq ($(wildcard $(WORKING_DIR)/VERSION),)
  VERSION ?= $(shell cat $(WORKING_DIR)/VERSION)-$(CIRCLE_BUILD_NUM)
endif

ifneq ($(wildcard $(WORKING_DIR)/package.json),)
  VERSION ?= $(shell awk '/"version":/{gsub(/("|",)/,"",$$2);print $$2};' \
                     package.json)-$(CIRCLE_BUILD_NUM)
endif

VERSION   ?= 0.0-$(CIRCLE_BUILD_NUM)

# Overwritable variables
#
ORG                   ?= breather
MAINTAINER            ?= platform+docker@breather.com
NAME                  ?= $(basename $(PWD))
TAG                   ?= $(VERSION)
TAG_BUILD             ?= $(CIRCLE_SHA1)
TAG_LATEST            ?= latest

# Constructed variables
#
IMG                   ?= $(ORG)/$(NAME)
IMG_BUILD             ?= $(IMG):$(TAG_BUILD)
IMG_TAGGED            ?= $(IMG):$(TAG)
IMG_LATEST            ?= $(IMG):$(TAG_LATEST)

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
		--cache-from $(IMG_BUILD) \
		--cache-from $(IMG_BUILD)-$(DOCKER_TARGET) \
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
		--cache-from $(IMG_BUILD)-$(DOCKER_TARGET) \
		--file $(DOCKER_FILE) \
		--tag $(IMG_BUILD)-$(DOCKER_TARGET) \
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

self.upgrade: ## Upgrade this instance of the Makefile
	$(WGET_CMD) --unlink -q $(SCRIPT_SOURCE) -O Makefile
