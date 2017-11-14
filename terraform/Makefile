# Makefile config
#
.DEFAULT = help
.PHONY: $(MAKEFILE_LIST)
SHELL := '/bin/bash'
SCRIPT_BASE   := https://raw.githubusercontent.com/breather/makefiles
SCRIPT_SOURCE := $(SCRIPT_BASE)/master/terraform/Makefile

# Include config file
#
CNF   ?= .env.make
-include ${CNF}
-include ${CNF}.local
-include Makefile.local

# Command variables
#
AWS_PROFILE           ?= $(AWS_ENV)

ASSUME                ?= $(shell which assume-role)
ASSUME_CMD            ?= $(ASSUME) $(AWS_PROFILE)
AWS                   ?= $(shell which aws)
AWS_CMD               ?= $(AWS) $(AWS_FLAGS)
AWS_FLAGS             ?= --profile $(AWS_PROFILE)
TERRAFORM             ?= $(shell which terraform)
TERRAFORM_CMD         ?= $(ASSUME_CMD) $(TERRAFORM) $(TERRAFORM_FLAGS)
TERRAFORM_FLAGS       ?=
WGET                  ?= $(shell which wget)
WGET_CMD              ?= $(WGET) $(WGET_FLAGS)
WGET_FLAGS            ?=

# Define usage / help
#
define USAGE
echo "NAME"
echo "  Terraform makefile"
echo
echo "SYNOPSIS"
echo "  make [subcommands] [-e VAR=VALUE]"
echo
echo "DESCRIPTION"
echo "  This terraform makefile wraps common workflows so as to simplify them."
echo
echo "CONFIGURATION"
echo "  Configurations may be provided in the follow locations, in order of precedence:"
echo "  - commandline argument: make -e VAR=VALUE"
echo "  - environment variable"
echo "  - ./Makefile.local"
echo "  - ./.env.make.local"
echo "  - ./.env.make"
echo
echo "AWS Profile"
echo "  Make will wrap all calls to 'terraform' or made with the 'exec' target"
echo "  with an assume-role utilizing your AWS_PROFILE."
echo
echo "  If 'AWS_PROFILE' is undefined, it will default to 'AWS_ENV' which should always"
echo "  be one of 'use1dev1' or 'use1prod' to reflect the execution environment."
echo
echo "SUBCOMMANDS"
endef

# Ensure the presence of required variables
#
ifeq ($(ASSUME),)
  $(info  command `assume-role` is missing)
  $(info  install it via `brew install remind101/formulae/assume-role`)
  $(error missing dependencies)
endif

ifeq ($(AWS_ENV),)
  $(info variable `AWS_ENV` is not defined, should be use1dev or use1prod)
  $(error missing dependencies)
endif

ifeq ($(TERRAFORM),)
  $(info  command `terraform` is missing)
  $(info  install it via `brew install terraform`)
  $(error missing dependencies)
endif

# Targets
#

help: ## Show this help message.
	@$(USAGE)
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

activate: ## Activate terraform workspace
ifndef ENV
	$(error "ENV was not set")
endif
	$(TERRAFORM_CMD) workspace select $(ENV)

apply: ## Apply terraform template
	@echo "Applying changes to Infrastracture"
	$(TERRAFORM_CMD) apply -parallelism=80 .tmp/plan_stg
	@make clean

confirm:
	@read -r -t 5 -p "Do you wish to continue (timeout 5s) [y/n]: " CONTINUE; \
	if [ ! $$CONTINUE == "y" ] || [ -z $$CONTINUE ]; then \
		echo "Aborting" ; \
		exit 1; \
	fi

clean: ## Delete temporary files
	rm -f .tmp/plan_stg #$(TERRAFORM_CMD).tfstate*

destroy: ## Delete terraform stack
	@echo "Destroying terraform stack"
	@make confirm
	$(TERRAFORM_CMD) destroy -force

exec: ## Execute an arbitrary command, requires -e CMD="command to exec"
	$(ASSUME_CMD) $(CMD)

format: ## Format terraform files
	@echo "Formating terraform code"
	$(TERRAFORM_CMD) fmt

get: ## Update terraform modules
	@echo "Updating terraform modules"
	$(TERRAFORM_CMD) get -update

init: ## Initialize terraform state
	@echo
	@echo "Ensuring required CLI tools exist"
	aws --version
	$(TERRAFORM_CMD) -version
	@echo "Initializing terraform state"
	$(TERRAFORM_CMD) init \
  -backend-config="acl=private" \
  -backend-config="bucket=breather-$(AWS_ENV)-terraform" \
  -backend-config="key=$(AWS_ENV)/$(BACKEND_KEY)" \
  -backend-config="dynamodb_table=$(AWS_ENV)-terraform" \
  -backend-config="region=us-east-1" \
  -force-copy \
  -input=false
	@echo
	@echo "Your environment: $$($(TERRAFORM_CMD) workspace list | grep '^\*' | awk '{print $$2}')"

plan: format get ## Verify infrastructure changes
	@echo "Checking Infrastracture"
	@mkdir -p .tmp || true
	$(TERRAFORM_CMD) plan \
  -parallelism=80 \
  -refresh=true \
  -module-depth=-1 \
  -out .tmp/plan_stg

setup: init get

show: ## Show infrastructure change plan
	@echo "Showing plan to apply"
	$(TERRAFORM_CMD) show .tmp/plan_stg

output: ## Show infrastructure outputs
	@$(TERRAFORM_CMD) output

self.upgrade: ## Upgrade this instance of the Makefile
	$(WGET_CMD) --unlink -q $(SCRIPT_SOURCE) -O Makefile

#  vim: set ft=make ts=2 sw=2 noet :
