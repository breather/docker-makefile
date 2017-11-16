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
AWS_PROFILE           ?= $(ENV)

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

BACKEND_BUCKET        ?= "breather-use1prod-terraform"
BACKEND_TABLE         ?= "terraform"

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
echo "  Although many configuration parameters are available (see source), only"
echo "  the options below should be used in day to day operations:"
echo "  - -e ENV=<environment_name>: Manage terraform in the named environment"
echo
echo "AUTHENTICATION"
echo "  Make will wrap all calls to 'terraform' or made with the 'exec' target"
echo "  with an assume-role utilizing your AWS_PROFILE."
echo
echo "  If 'AWS_PROFILE' is undefined, it will default to 'ENV' which should always"
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

ifeq ($(ENV),)
  $(info variable `ENV` is not defined, should be use1dev or use1prod)
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
	@echo
	@echo "Activating workspace $(ENV)"
	@{ \
		if [ "$$(cat .terraform/environment | true)" != "$(ENV)" ]; then \
			$(TERRAFORM_CMD) workspace select $(ENV); \
		fi; \
	}

apply: activate ## Apply terraform template
	@echo
	@echo "Applying changes to Infrastracture"
	$(TERRAFORM_CMD) apply -parallelism=80 .tmp/plan.$(ENV)
	@make clean

confirm:
	@read -r -t 5 -p "Do you wish to continue (timeout 5s) [y/n]: " CONTINUE; \
	if [ ! $$CONTINUE == "y" ] || [ -z $$CONTINUE ]; then \
		echo "Aborting" ; \
		exit 1; \
	fi

clean: ## Delete temporary files
	rm -f .tmp/plan.*

destroy: ## Delete terraform stack
	@echo
	@echo "Destroying terraform stack"
	@make confirm
	$(TERRAFORM_CMD) destroy -force

exec: ## Execute an arbitrary command, requires -e CMD="command to exec"
	$(ASSUME_CMD) $(CMD)

format: ## Format terraform files
	@echo
	@echo "Formating terraform code"
	$(TERRAFORM_CMD) fmt

get: ## Update terraform modules
	@echo
	@echo "Updating terraform modules"
	$(TERRAFORM_CMD) get -update
	$(TERRAFORM_CMD) workspace select $(ENV)

init: ## Initialize terraform state
	@{ \
		[ -f .terraform/terraform.tfstate ] \
		&& $(TERRAFORM_CMD) workspace new $(ENV) \
		|| true; \
	}
	@echo "Ensuring required CLI tools exist"
	@echo
	aws --version
	$(TERRAFORM_CMD) -version
	@echo "Initializing terraform state"
	@echo
	$(TERRAFORM_CMD) init \
  -backend-config="acl=private" \
  -backend-config="bucket=$(BACKEND_BUCKET)" \
  -backend-config="dynamodb_table=$(BACKEND_TABLE)" \
  -backend-config="key=$(BACKEND_KEY)" \
  -backend-config="workspace_key_prefix=workspace" \
  -backend-config="region=us-east-1" \
  -force-copy \
  -input=false
	@echo
	@echo "Configuring workspace environment"
	@echo
	$(TERRAFORM_CMD) workspace new $(ENV) || true

plan: activate format get ## Verify infrastructure changes
	@echo
	@echo "Checking Infrastracture"
	@mkdir -p .tmp || true
	$(TERRAFORM_CMD) plan \
  -module-depth=-1 \
  -out .tmp/plan.$(ENV) \
  -parallelism=80 \
  -refresh=true \
  -var-file config/default.tfvars \
  -var-file config/$(ENV).tfvars

setup: init get

show: ## Show infrastructure change plan
	$(TERRAFORM_CMD) show .tmp/plan.$(ENV)

state-list: activate ## List terraform resources
	$(TERRAFORM_CMD) state list

state-show: activate ## Show terraform resource, -e ID="XXX"
	$(TERRAFORM_CMD) state show $(ID)

output: ## Show infrastructure outputs
	@$(TERRAFORM_CMD) output

self.upgrade: ## Upgrade this instance of the Makefile
	$(WGET_CMD) --unlink -q $(SCRIPT_SOURCE) -O Makefile

#  vim: set ft=make ts=2 sw=2 noet :
