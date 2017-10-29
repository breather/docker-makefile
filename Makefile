# Makefile config
#
.DEFAULT = help
.PHONY: $(MAKEFILE_LIST)
SHELL := '/bin/bash'
SCRIPT_SOURCE := https://raw.githubusercontent.com/breather/docker-makefile/master/Makefile

# Command variables
#
AWS                    = aws
AWS_CMD                = $(AWS) $(AWS_FLAGS)
AWS_FLAGS              = #--profile $(AWS_PROFILE)
AWS_PROFILE           ?= default
COMPOSE                = docker-compose
COMPOSE_CMD            = $(COMPOSE) -f $(COMPOSE_FILE) $(COMPOSE_FLAGS)
COMPOSE_FILE           = docker-compose
COMPOSE_FLAGS          =
DOCKER                 = docker
DOCKER_CMD             = $(DOCKER) $(DOCKER_FLAGS)
DOCKER_FILE           ?= Dockerfile
DOCKER_FLAGS           =
WGET                   = wget
WGET_CMD               = $(WGET) $(WGET_FLAGS)
WGET_FLAGS             =

# Optionally include config file
#
CNF ?= .env.make
-include ${CNF}
-include ${CNF}.local
-include ${WORKING_DIR}/Makefile.local

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

assume: ## Assume an aws role and export session credentials
ifndef AWS_ROLE_ARN
else
	CREDENTIALS := $(shell aws sts assume \
		--role-arn ${AWS_ROLE_ARN} \
		--role-session-name=${NAME} \
		--query Credentials \
		--output text)
	export AWS_ACCESS_KEY_ID     := $(word 1, $(CREDENTIALS))
	export AWS_SECRET_ACCESS_KEY := $(word 3, $(CREDENTIALS))
	export AWS_SESSION_TOKEN     := $(word 4, $(CREDENTIALS))
endif

assume-exec: assume ## Assume an aws role and execute COMMAND="cmd args"
	$(COMMAND)

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

login: ## Login to repository
ifneq (,$(findstring amazonaws.com,$(ORG)))
	$$($(AWS_CMD) ecr get-login --no-include-email)
else
	@$(DOCKER_CMD) login --username $(DOCKER_USER) --password $(DOCKER_PASS)
endif

pull: login ## Pull tagged docker image from repository
	$(DOCKER_CMD) pull $(PULL_FLAGS) $(IMG_TAGGED)

push: login ## Push tagged docker image to repository
	$(DOCKER_CMD) push $(PUSH_FLAGS) $(IMG_TAGGED)

tag: ## Tag build image
ifneq ($(IMG_BUILD),$(IMG_TAGGED))
	$(DOCKER_CMD) tag $(IMG_BUILD) $(IMG_TAGGED)
endif

tag.latest:
	$(DOCKER_CMD) tag $(IMG_BUILD) $(IMG_LATEST)

print.tags: ## Print current build tag
	@echo $(TAG_BUILD)

self.upgrade: ## Upgrade this instance of the Makefile
	$(WGET_CMD) --unlink -q $(SCRIPT_SOURCE) -O Makefile
