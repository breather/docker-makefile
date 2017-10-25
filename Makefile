# Makefile config
#
.DEFAULT_GOAL := help
.PHONY: help
SHELL := '/bin/bash'
SCRIPT_SOURCE := https://raw.githubusercontent.com/breather/docker-makefile/master/Makefile

# Dynamic variables
#
AWS_PROFILE           ?= default
BUILD_DATE            ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
CIRCLE_BRANCH         ?= $(shell git rev-parse --abbrev-ref HEAD)
CIRCLE_BUILD_NUM      ?= local
CIRCLE_REPOSITORY_URL ?= $(shell git config --get remote.origin.url)
CIRCLE_SHA1           ?= $(shell git rev-parse HEAD)
WORKING_DIR           ?= $(shell pwd)

# Optionally include config file
#
CNF ?= .env.make
-include ${CNF}
-include ${WORKING_DIR}/Makefile.local

# Overwritable variables
#
ORG        ?= breather
MAINTAINER ?= platform+docker@breather.com
NAME       ?= $(shell basename $(shell pwd))
TAG        ?= ${CIRCLE_SHA1}
TAG_BUILD  ?= ${CIRCLE_SHA1}
TAG_LATEST ?= latest
VERSION    ?= 0.0

# Constructed variables
#
IMG        ?= ${ORG}/${NAME}
IMG_BUILD  ?= ${IMG}:${TAG_BUILD}
IMG_TAGGED ?= ${IMG}:${TAG}
IMG_LATEST ?= ${IMG}:${TAG_LATEST}

# Targets
#
help: ## Show this help message.
	@echo 'Docker image builder'
	@echo
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

build: login ## Build docker container
	cd ${WORKING_DIR}; docker build \
    $(if $(CACHE_FROM),--cache-from $(CACHE_FROM),) \
    --label maintainer=${MAINTAINER} \
    --label org.label-schema.build-date=${BUILD_DATE} \
    --label org.label-schema.name=${NAME} \
    --label org.label-schema.vcs-ref=${CIRCLE_SHA1} \
    --label org.label-schema.vcs-url=${CIRCLE_REPOSITORY_URL} \
    --label org.label-schema.vcs-branch=${CIRCLE_BRANCH} \
    --label org.label-schema.version=${VERSION} \
    --tag ${IMG_BUILD} \
    ${BUILD_ARGS} \
    .

login: ## Login to repository
ifneq (,$(findstring amazonaws.com,$(ORG)))
	$$(aws ecr get-login --no-include-email)
else
	@docker login --username ${DOCKER_USER} --password ${DOCKER_PASS}
endif

assume-role: ## Assume an aws role and export session credentials
ifndef AWS_ROLE_ARN
else
  CREDENTIALS := $(shell aws sts assume-role \
    --role-arn ${AWS_ROLE_ARN} \
    --role-session-name=${NAME} \
    --query Credentials \
    --output text)
  export AWS_ACCESS_KEY_ID     := $(word 1, $(CREDENTIALS))
  export AWS_SECRET_ACCESS_KEY := $(word 3, $(CREDENTIALS))
  export AWS_SESSION_TOKEN     := $(word 4, $(CREDENTIALS))
endif

assume-exec: assume-role ## Assume an aws role and execute COMMAND="cmd args"
	$(COMMAND)

pull: login ## Pull tagged docker image from repository
	docker pull ${IMG_TAGGED}

push: login ## Push tagged docker image to repository
	docker push ${IMG_TAGGED}

push-latest: login ## Push latest docker image to repository
ifeq ($(CIRCLE_BRANCH), master)
	docker push ${IMG_LATEST}
endif

self-upgrade: ## Upgrade this instance of the Makefile
	wget --unlink -q ${SCRIPT_SOURCE} -O Makefile

tag: ## Tag build image
ifneq (${IMG_BUILD},${IMG_TAGGED})
	docker tag ${IMG_BUILD} ${IMG_TAGGED}
endif

tag-latest:
ifeq ($(CIRCLE_BRANCH), master)
	docker tag ${IMG_BUILD} ${IMG_LATEST}
endif
