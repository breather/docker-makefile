#
# Makefile config
#
MAKEFLAGS       += --warn-undefined-variables
SHELL           := bash
.SHELLFLAGS     := -eu -o pipefail -c
.DEFAULT_GOAL   := help
.DELETE_ON_ERROR:
.SUFFIXES:

#
# Makefile source
#
MAKEFILE_PATH    ?= $(firstword $(MAKEFILE_LIST))
MAKEFILE_VERSION ?= master
MAKEFILE_SOURCE   = https://raw.githubusercontent.com/breather
MAKEFILE_SOURCE  := $(MAKEFILE_SOURCE)/makefiles/$(MAKEFILE_VERSION)
MAKEFILE_SOURCE  := $(MAKEFILE_SOURCE)/docker/Makefile

#
# Pathing variables
#
MAKEDIR  ?= $(realpath $(dir $(firstword $(MAKEFILE_LIST))))
IMAGEDIR ?= $(realpath $(MAKEDIR)/..)
WORKDIR  ?= $(realpath $(IMAGEDIR)/../..)

#
# Includes
#
-include $(IMAGEDIR)/Makefile.local

#
# Default variables meant to be overriden
#
AWS_PROFILE           ?= default

# -- Defined in the Build environment variables
BRANCH                ?= $(CIRCLE_BRANCH)
BUILD                 ?= $(CIRCLE_BUILD_NUM)
MESSAGE               ?= $(shell printf '%q' "$$(git --no-pager log --pretty=format:'%s' -1 | sed -e "s@'@\"@g")")
REPO_URL              ?= $(CIRCLE_REPOSITORY_URL)
REVISION              ?= $(shell git --no-pager log --pretty=format:'%h' -1)

# -- Defined in the Build version variables
#VERSION               ?= $(VERSION)

# -- Image origin default variables
ORG                   ?= breather
MAINTAINER            ?= platform+docker@breather.com
NAME                  ?= $(shell basename $(WORKDIR))
IMAGE                 ?= $(ORG)/$(NAME)

# -- Image name prefixes
NODE_ENV              ?= production
ifeq ($(NODE_ENV),production)
  PREFIX              ?= prod-
endif
PREFIX                ?= dev-

# -- Image tagging default variables
BUILD_TAG             ?= $(PREFIX)$(REVISION)
LATEST_TAG            ?= $(PREFIX)latest
LOCAL_TAG             ?= $(PREFIX)local
RELEASE_TAG           ?= $(PREFIX)$(VERSION)-latest
SOURCE_TAG            ?= $(BUILD_TAG)
VERSION_TAG           ?= $(PREFIX)$(VERSION)-$(BUILD)

#
# Default Build environment variables
#
BUILD_DATE            ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_ARGS            ?=
CACHE_IMAGES          ?=
CIRCLE_BRANCH         ?= $(shell git rev-parse --abbrev-ref HEAD)
CIRCLE_BUILD_NUM      ?= local
CIRCLE_REPOSITORY_URL ?= $(shell git config --get remote.origin.url)
CIRCLE_SHA1           ?= $(shell git rev-parse HEAD)

#
# Default Build version variables
#
VERSION_FILE          ?= $(WORKDIR)/VERSION

ifneq ($(wildcard $(VERSION_FILE)),)
  VERSION             ?= $(shell cat $(VERSION_FILE))
endif

ifneq ($(wildcard $(WORKDIR)/package.json),)
  VERSION             ?= $(shell jq -r .version $(WORKDIR)/package.json)
endif

VERSION               ?= 0.0

#
# Commands
#
AWS                   ?= $(AWS_CMD) $(AWS_FLAGS)
AWS_CMD               ?= aws
ifneq ($(AWS_PROFILE),default)
  AWS_FLAGS           ?= --profile $(AWS_PROFILE)
else
  AWS_FLAGS           ?=
endif

DOCKER                ?= $(DOCKER_CMD) $(DOCKER_FLAGS)
DOCKER_CMD            ?= docker
DOCKER_FLAGS          ?=
DOCKER_FILE           ?= $(MAKEDIR)/Dockerfile

PULL_FLAGS            ?=
PUSH_FLAGS            ?=

#
# Non-docker targets
#
make.update: ## Updates the makefile from git
make.update: .phony
	@wget --unlink -q -O $(MAKEFILE_PATH) $(MAKEFILE_SOURCE)

#
# Internal targets
#
.PHONY: .phony
.phony: # Dummy target used to force run

#
# Help target
#
.PHONY: help
help:
	@echo Docker makefile
	@echo
	@echo Variables
	@printf "\033[36m%-20s\033[0m %s\n" ORG "$(ORG)"
	@printf "\033[36m%-20s\033[0m %s\n" NAME "$(NAME)"
	@printf "\033[36m%-20s\033[0m %s\n" MESSAGE "$(MESSAGE)"
	@printf "\033[36m%-20s\033[0m %s\n" VERSION "$(VERSION)-$(BUILD)"
	@printf "\033[36m%-20s\033[0m %s\n" PREFIX "$(PREFIX)"
	@echo
	@printf "\033[36m%-20s\033[0m %s\n" BUILD_TAG "$(BUILD_TAG)"
	@printf "\033[36m%-20s\033[0m %s\n" LATEST_TAG "$(LATEST_TAG)"
	@printf "\033[36m%-20s\033[0m %s\n" LOCAL_TAG "$(LOCAL_TAG)"
	@printf "\033[36m%-20s\033[0m %s\n" RELEASE_TAG "$(RELEASE_TAG)"
	@printf "\033[36m%-20s\033[0m %s\n" SOURCE_TAG "$(SOURCE_TAG)"
	@printf "\033[36m%-20s\033[0m %s\n" VERSION_TAG "$(VERSION_TAG)"
	@echo
	@echo Targets:
	@grep -hE '^[a-zA-Z_\-\.]+(.%)?:.*?## .*$$' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

#
# Targets
#
build: build.image ## Build docker image (build.image)

build.image: .phony ## Build docker image
	cd $(WORKDIR); $(DOCKER) build \
  --file $(DOCKER_FILE) \
  --label maintainer=$(MAINTAINER) \
  --label org.label-schema.build-date=$(BUILD_DATE) \
  --label org.label-schema.description=$(MESSAGE) \
  --label org.label-schema.name=$(NAME) \
  --label org.label-schema.vcs-ref=$(REVISION) \
  --label org.label-schema.vcs-url=$(REPO_URL) \
  --label org.label-schema.vcs-branch=$(BRANCH) \
  --label org.label-schema.version=$(VERSION)-$(BUILD) \
  --tag $(IMAGE):$(BUILD_TAG) \
  $(BUILD_ARGS) \
  $(addprefix --cache-from ,$(CACHE_IMAGES)) \
  .

build.target.%: .phony ## Build docker image target named %
	$(DOCKER) build \
  --file $(DOCKER_FILE) \
  --tag $(IMAGE):$(BUILD_TAG)-$* \
  --target $* \
  $(BUILD_ARGS) \
  $(addprefix --cache-from ,$(CACHE_IMAGES)) \
  $(WORKDIR)

login: .phony ## Login to docker registry
ifneq (,$(findstring amazonaws.com,$(ORG)))
	$$($(AWS) ecr get-login --no-include-email)
else
	@$(DOCKER) login --username $(DOCKER_USER) --password $(DOCKER_PASS)
endif

print.var.%: .phony ## Prints the value of a variable
	@echo $($*)

print.image.%: .phony ## Prints the value of an image with tag
	@echo $(IMAGE):$($*)

pull: .phony ## Push docker image named -e TAG=XXX
	$(DOCKER) pull $(PULL_FLAGS) $(IMAGE):$(TAG)

pull.%: .phony ## Push docker image with provided variable as tag
	$(DOCKER) pull $(PULL_FLAGS) $(IMAGE):$($*)

push: .phony ## Pull docker image named -e TAG=XXX
	$(DOCKER) push $(PUSH_FLAGS) $(IMAGE):$(TAG)

push.%: .phony ## Pull docker image with provided variable as tag
	$(DOCKER) push $(PUSH_FLAGS) $(IMAGE):$($*)

tag: .phony ## Tag docker SOURCE_TAG image as -e TAG=XXX
	$(DOCKER) tag $(IMAGE):$(SOURCE_TAG) $(IMAGE):$(TAG)

tag.%: .phony ## Tag docker SOURCE_TAG image with provided variable as tag
	$(DOCKER) tag $(IMAGE):$(SOURCE_TAG) $(IMAGE):$($*)
	@echo $($*)
